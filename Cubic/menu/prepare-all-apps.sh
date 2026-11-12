#!/usr/bin/env bash
set -Eeuo pipefail

source "${1:-$HOME/app-iso.conf}"
: "${ROOT:?ROOT not set}" "${STAGING:?STAGING not set}"

ROOT="$(realpath -e "$ROOT")"   # Phải tồn tại trước
mkdir -p "$STAGING/apps" "$STAGING/deb-cache"
STAGING="$(realpath -e "$STAGING")"

echo "ROOT: $ROOT"
echo "STAGING: $STAGING"

make_id() {
    python3 -c "import re,sys,unicodedata as u;s=u.normalize('NFKD',sys.argv[1]).encode('ascii','ignore').decode();print(re.sub(r'[^A-Za-z0-9]+','-',s).strip('-').lower())" "$1"
}

packages_for_binary() {
    local bin="$1"
    local appdir="$2"
    local arch
    local lib real pkg candidate

    arch="$(dpkg --print-architecture)"

    while IFS= read -r lib; do
        [[ -n "$lib" ]] || continue

        # Bỏ qua thư viện đã đóng gói cùng ứng dụng
        [[ "$lib" == "$appdir/"* ]] && continue

        # Các thư viện Qt cài từ /opt/Qt không thuộc package dpkg
        if [[ "$lib" == /opt/Qt/* ]]; then
            echo "EXTERNAL Qt library: $lib" >&2
            continue
        fi

        # Chuẩn hóa đường dẫn merged-/usr và symlink
        real="$(readlink -f -- "$lib" 2>/dev/null || true)"

        pkg=""

        # Thử cả đường dẫn ban đầu và đường dẫn thực
        for candidate in "$lib" "$real"; do
            [[ -n "$candidate" ]] || continue

            pkg="$(
                dpkg-query -S "$candidate" 2>/dev/null |
                awk -F': ' '
                    !/^diversion by / && NF >= 2 {
                        print $1
                        exit
                    }
                '
            )"

            [[ -n "$pkg" ]] && break
        done

        if [[ -n "$pkg" ]]; then
            # Bỏ architecture suffix nếu có
            pkg="${pkg%:$arch}"
            echo "$pkg"
        else
            echo "WARNING: Cannot find package owner: $lib" >&2
        fi

    done < <(
        ldd "$bin" 2>/dev/null |
        awk '
            /=>/ && $3 ~ /^\// {
                print $3
                next
            }

            $1 ~ /^\// {
                print $1
            }
        ' | sort -u
    )
}
dependency_closure() {
    [[ $# -eq 0 ]] && return 0

    apt-rdepends --follow=Depends,PreDepends "$@" 2>/dev/null |
        awk '/^[^[:space:]]+$/ {print $1}' |
        sort -u |
        while IFS= read -r pkg; do
            [[ -n "$pkg" ]] || continue

            candidate="$(
                apt-cache policy "$pkg" 2>/dev/null |
                awk '/Candidate:/ {print $2; exit}'
            )"

            if [[ -n "$candidate" && "$candidate" != "(none)" ]]; then
                echo "$pkg"
            fi
        done
}
declare -A ALL_PKGS=()
APP_COUNT=0

for dir in "${APP_BUILD_DIRS[@]}"; do
    echo "====================================="
    [[ -d "$dir" ]] || { echo "ERROR: $dir not found"; exit 1; }
    dir="$(realpath -e "$dir")"
    
    name="$(basename "$dir")"
    [[ "$name" =~ ^(build|bin|out|dist)$ ]] && name="$(basename "$(dirname "$dir")")"
    
    id="$(make_id "$name")"
    [[ -z "$id" ]] && { echo "ERROR: Invalid name: $name"; exit 1; }
    
    echo "App: $name (ID: $id)"
    
    appdir="$STAGING/apps/$id"
    mkdir -p "$appdir"
    cp -a "$dir"/. "$appdir"/
    
    # Clean
    find "$appdir" -type d \( -name CMakeFiles -o -name .git \) -exec rm -rf {} + 2>/dev/null || true
    find "$appdir" -type f \( -name '*.o' -o -name CMakeCache.txt \) -delete 2>/dev/null || true
    
    # Find executable
    mapfile -t exes < <(find "$appdir" -type f -executable -exec file {} + | awk -F: '/ELF.*executable/{print $1}')
    [[ ${#exes[@]} -eq 1 ]] || { echo "ERROR: Need 1 ELF in $id, found ${#exes[@]}"; exit 1; }
    
    exe="${exes[0]}"
    exe_rel="${exe#$appdir/}"
    echo "Executable: $exe_rel"
    
    # Get dependencies
    mapfile -t root_pkgs < <(packages_for_binary "$exe" "$appdir")
    root_pkgs+=("${EXTRA_APT_PACKAGES[@]}")
    mapfile -t all_pkgs < <(dependency_closure "${root_pkgs[@]}")
    for p in "${all_pkgs[@]}"; do ALL_PKGS["$p"]=1; done
    echo "Dependencies: ${#all_pkgs[@]} packages"
    
    # Metadata
    jq -n \
        --arg id "$id" \
        --arg name "$name" \
        --arg exe "$exe_rel" \
        --argjson req "$(printf '%s\n' "${all_pkgs[@]}" | jq -Rs 'split("\n")|map(select(length>0))')" \
        '{id:$id,name:$name,version:"1.0.0",description:$name,executable:$exe,requires:$req}' \
        > "$appdir/metadata.json"
    
    # Run script
    cat > "$appdir/run.sh" <<EOF
#!/bin/bash
set -e
cd "\$(dirname "\$0")"
[[ -r /etc/profile.d/cubic-dev-environment.sh ]] && source /etc/profile.d/cubic-dev-environment.sh 2>/dev/null || true
export LD_LIBRARY_PATH="\$PWD/lib:\${LD_LIBRARY_PATH:-}"
export QT_PLUGIN_PATH="\$PWD/plugins:\${QT_PLUGIN_PATH:-}"
export QML2_IMPORT_PATH="\$PWD/qml:\${QML2_IMPORT_PATH:-}"
exec "\$PWD/$exe_rel" "\$@"
EOF
    chmod 755 "$appdir/run.sh" "$exe"
    APP_COUNT=$(( APP_COUNT + 1 ))
done

echo "====================================="
echo "Total apps: $APP_COUNT"

# Download .deb
mapfile -t pkgs < <(printf '%s\n' "${!ALL_PKGS[@]}" | sort -u)
if [[ ${#pkgs[@]} -gt 0 ]]; then
    echo "Downloading ${#pkgs[@]} packages..."
    sudo apt-get install -y --download-only --reinstall --no-install-recommends \
        -o "Dir::Cache::archives=$STAGING/deb-cache/" "${pkgs[@]}"
    sudo chown -R $(id -u):$(id -g) "$STAGING/deb-cache"
    rm -rf "$STAGING/deb-cache/partial" "$STAGING/deb-cache/lock"
    
    # Create APT index
    ( cd "$STAGING/deb-cache" && dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz )
    echo ".deb files: $(find "$STAGING/deb-cache" -name '*.deb' | wc -l)"
fi

echo "====================================="
echo " Staging complete: $STAGING"


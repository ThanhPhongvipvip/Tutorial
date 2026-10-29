# C++ Cơ Bản và OOP

## A. Bốn Nguyên Tắc OOP

### 1. Đóng Gói (Encapsulation)

**Định nghĩa:** Đóng gói là việc gom **dữ liệu (thuộc tính)** và **phương thức xử lý dữ liệu** vào cùng một lớp, đồng thời kiểm soát quyền truy cập để bảo vệ tính toàn vẹn của dữ liệu.

#### Access Specifiers (Phạm vi truy cập)

| Specifier | Truy cập trong lớp | Truy cập từ lớp con | Truy cập từ bên ngoài |
|:----------|:------------------:|:-------------------:|:---------------------:|
| `private` | ✓ | ✗ | ✗ |
| `protected` | ✓ | ✓ | ✗ |
| `public` | ✓ | ✓ | ✓ |

#### Ví dụ thực tế

```cpp
#include <iostream>
#include <string>

class BankAccount {
private:
    std::string accountNumber;  // Chỉ truy cập bên trong lớp
    double balance;             // Bảo vệ dữ liệu nhạy cảm

public:
    BankAccount(const std::string& accNum, double initialBalance) 
        : accountNumber(accNum), balance(initialBalance) {}

    // Getter - Truy cập an toàn
    double getBalance() const {
        return balance;
    }

    // Method với logic kiểm tra
    bool withdraw(double amount) {
        if (amount <= 0) {
            std::cout << "Số tiền không hợp lệ\n";
            return false;
        }
        if (amount > balance) {
            std::cout << "Số dư không đủ\n";
            return false;
        }
        balance -= amount;
        return true;
    }

    void deposit(double amount) {
        if (amount > 0) {
            balance += amount;
        }
    }
};
```

**Lợi ích:**
-  Bảo vệ dữ liệu khỏi truy cập trực tiếp
-  Kiểm soát logic nghiệp vụ
-  Dễ bảo trì: thay đổi implementation mà không ảnh hưởng code bên ngoài

---

### 2. Kế Thừa (Inheritance)

**Định nghĩa:** Kế thừa cho phép lớp con (derived class) sử dụng và mở rộng thuộc tính/phương thức của lớp cha (base class). Áp dụng khi có quan hệ **"is-a"** (là một).

#### Các kiểu kế thừa

```cpp
class Derived : public Base { };      // Public inheritance (phổ biến nhất)
class Derived : protected Base { };   // Protected inheritance
class Derived : private Base { };     // Private inheritance
```

| Kế thừa | public trong Base | protected trong Base | private trong Base |
|:--------|:------------------|:--------------------|:------------------|
| `public` | → public | → protected | ✗ không truy cập |
| `protected` | → protected | → protected | ✗ không truy cập |
| `private` | → private | → private | ✗ không truy cập |

#### Ví dụ

```cpp
#include <iostream>
#include <string>

// Lớp cơ sở
class Person {
protected:  // Cho phép lớp con truy cập
    std::string name;
    int age;

public:
    Person(const std::string& n, int a) : name(n), age(a) {}

    virtual void introduce() const {
        std::cout << "Tôi là " << name << ", " << age << " tuổi\n";
    }

    virtual ~Person() = default;  // Virtual destructor quan trọng!
};

// Lớp dẫn xuất
class Student : public Person {
private:
    double gpa;

public:
    Student(const std::string& n, int a, double g)
        : Person(n, a), gpa(g) {}

    void introduce() const override {
        std::cout << "Sinh viên " << name << ", GPA: " << gpa << "\n";
    }
};
```

**Lợi ích:**
-  Tái sử dụng code (DRY principle)
-  Mở rộng chức năng mà không sửa lớp cơ sở
-  Tạo cấu trúc phân cấp logic

---

### 3. Đa Hình (Polymorphism)

**Định nghĩa:** Đa hình là khả năng cùng một giao diện tạo ra hành vi khác nhau tùy đối tượng.

#### Các loại đa hình trong C++

1. **Compile-time Polymorphism** (Static):
   - Function overloading
   - Operator overloading
   - Templates

2. **Runtime Polymorphism** (Dynamic):
   - Virtual functions
   - Function overriding

#### Ví dụ với Virtual Functions

```cpp
#include <iostream>
#include <vector>
#include <memory>

class Shape {
public:
    virtual double area() const = 0;  // Pure virtual function
    virtual void draw() const {
        std::cout << "Drawing a shape\n";
    }
    virtual ~Shape() = default;
};

class Circle : public Shape {
private:
    double radius;

public:
    explicit Circle(double r) : radius(r) {}

    double area() const override {
        return 3.14159 * radius * radius;
    }

    void draw() const override {
        std::cout << "Drawing a circle with area: " << area() << "\n";
    }
};

class Rectangle : public Shape {
private:
    double width, height;

public:
    Rectangle(double w, double h) : width(w), height(h) {}

    double area() const override {
        return width * height;
    }

    void draw() const override {
        std::cout << "Drawing a rectangle with area: " << area() << "\n";
    }
};

int main() {
    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.push_back(std::make_unique<Circle>(5.0));
    shapes.push_back(std::make_unique<Rectangle>(4.0, 6.0));

    // Đa hình: cùng gọi draw() nhưng hành vi khác nhau
    for (const auto& shape : shapes) {
        shape->draw();
    }

    return 0;
}
```

**Output:**
```
Drawing a circle with area: 78.5398
Drawing a rectangle with area: 24
```

**Từ khóa quan trọng:**
- `virtual`: Cho phép override trong lớp con
- `override`: Đánh dấu rõ ràng hàm đang override (C++11+)
- `final`: Ngăn không cho override thêm
- `= 0`: Pure virtual function (lớp trở thành abstract)

**Virtual Table (vtable):**
- Cơ chế triển khai phổ biến: mỗi lớp có vtable chứa địa chỉ các virtual functions
- Đối tượng chứa con trỏ vptr trỏ đến vtable
- Chi phí: thêm 8 bytes (64-bit) cho mỗi đối tượng

---

### 4. Trừu Tượng (Abstraction)

**Định nghĩa:** Trừu tượng là việc ẩn chi tiết triển khai phức tạp, chỉ đưa ra giao diện cần thiết.

#### Abstract Class (Lớp trừu tượng)

Lớp có ít nhất một **pure virtual function** (`= 0`):

```cpp
class AbstractDatabase {
public:
    // Pure virtual functions - PHẢI implement trong lớp con
    virtual bool connect(const std::string& connectionString) = 0;
    virtual void disconnect() = 0;
    virtual bool execute(const std::string& query) = 0;

    // Virtual function với implementation mặc định
    virtual void log(const std::string& message) {
        std::cout << "[LOG] " << message << "\n";
    }

    virtual ~AbstractDatabase() = default;
};

// Concrete implementation
class MySQLDatabase : public AbstractDatabase {
public:
    bool connect(const std::string& connectionString) override {
        std::cout << "Connecting to MySQL: " << connectionString << "\n";
        return true;
    }

    void disconnect() override {
        std::cout << "Disconnecting from MySQL\n";
    }

    bool execute(const std::string& query) override {
        std::cout << "Executing MySQL query: " << query << "\n";
        return true;
    }
};
```

**Lợi ích:**
- ✓ Tách interface khỏi implementation
- ✓ Dễ mở rộng: thêm PostgreSQLDatabase, MongoDatabase, etc.
- ✓ Giảm coupling, tăng maintainability

---

## B. Con Trỏ và Tham Chiếu

### 1. Con Trỏ (Pointer)

**Định nghĩa:** Con trỏ là biến lưu **địa chỉ** của một đối tượng trong bộ nhớ.

#### Cú pháp cơ bản

```cpp
int value = 42;
int* ptr = &value;      // ptr lưu địa chỉ của value
*ptr = 100;             // Gán giá trị qua con trỏ (dereferencing)
std::cout << value;     // 100

// Con trỏ có thể NULL/nullptr
int* nullPtr = nullptr;
if (nullPtr == nullptr) {
    std::cout << "Con trỏ null\n";
}

// Con trỏ có thể trỏ đối tượng khác
int anotherValue = 200;
ptr = &anotherValue;    // Bây giờ ptr trỏ đến anotherValue
```

#### Con trỏ hằng (Pointer và const)

```cpp
int x = 10, y = 20;

// 1. Pointer to const: Không thể thay đổi GIÁ TRỊ qua con trỏ
const int* ptr1 = &x;
// *ptr1 = 15;  // LỖI: không thể thay đổi giá trị
ptr1 = &y;      // OK: có thể trỏ đối tượng khác

// 2. Const pointer: Không thể thay đổi ĐỊA CHỈ
int* const ptr2 = &x;
*ptr2 = 15;     // OK: có thể thay đổi giá trị
// ptr2 = &y;   // LỖI: không thể trỏ đối tượng khác

// 3. Const pointer to const: Cả hai đều không thể thay đổi
const int* const ptr3 = &x;
// *ptr3 = 15;  // LỖI
// ptr3 = &y;   // LỖI
```

**Mẹo nhớ:** Đọc từ phải sang trái:
- `const int*` = "pointer to const int"
- `int* const` = "const pointer to int"
- `const int* const` = "const pointer to const int"

---

### 2. Tham Chiếu (Reference)

**Định nghĩa:** Tham chiếu là **bí danh** (alias) của một đối tượng đã tồn tại.

#### So sánh Pointer vs Reference

| Đặc điểm | Pointer | Reference |
|:---------|:--------|:----------|
| Có thể null |  Có (`nullptr`) |  Không (phải liên kết) |
| Thay đổi target | Có thể |  Không thể (cố định) |
| Cần khởi tạo | Không bắt buộc |  Bắt buộc |
| Dereference | Cần `*ptr` | Tự động |
| Kích thước | 8 bytes (64-bit) | Không chiếm thêm (alias) |

#### Ví dụ

```cpp
#include <iostream>

void incrementByPointer(int* ptr) {
    if (ptr != nullptr) {
        (*ptr)++;
    }
}

void incrementByReference(int& ref) {
    ref++;  // Không cần kiểm tra null, đơn giản hơn
}

int main() {
    int value = 10;

    // Pointer
    int* ptr = &value;
    incrementByPointer(ptr);
    std::cout << value << "\n";  // 11

    // Reference
    int& ref = value;  // ref là bí danh của value
    incrementByReference(ref);
    std::cout << value << "\n";  // 12

    // Reference không thể rebind
    int another = 50;
    ref = another;  // Không phải rebind, mà là gán giá trị!
    std::cout << value << "\n";  // 50

    return 0;
}
```

**Khi nào dùng gì?**
- **Reference**: Khi biết chắc đối tượng tồn tại, muốn code sạch hơn
- **Pointer**: Khi cần biểu diễn "optional" (có thể null), hoặc cần rebind

---

## C. Quản Lý Bộ Nhớ

### 1. Stack vs Heap

#### Stack (Bộ nhớ ngăn xếp)

**Đặc điểm:**
- Tự động quản lý bởi compiler
- LIFO (Last In, First Out)
- Nhanh (chỉ di chuyển stack pointer)
- Kích thước giới hạn (thường 1-8 MB)
- Đối tượng bị hủy tự động khi ra khỏi scope

```cpp
void function() {
    int x = 10;        // Trên stack
    Student s("An");   // Trên stack
}  // x và s tự động bị hủy ở đây
```

#### Heap (Bộ nhớ động)

**Đặc điểm:**
- Quản lý thủ công (hoặc qua smart pointers)
- Kích thước lớn hơn (giới hạn bởi RAM)
- Chậm hơn (cần allocator quản lý)
- Phải giải phóng thủ công (`delete`)

```cpp
int* ptr = new int(42);        // Cấp phát trên heap
delete ptr;                    // Phải giải phóng thủ công
ptr = nullptr;                 // Tránh dangling pointer

int* arr = new int[100];       // Mảng động
delete[] arr;                  // Dùng delete[] cho mảng
```

---

### 2. new và delete

#### Cú pháp

```cpp
// Cấp phát đối tượng đơn
Type* ptr = new Type;           // Default constructor
Type* ptr = new Type(args);     // Constructor với tham số
delete ptr;                     // Giải phóng

// Cấp phát mảng
Type* arr = new Type[size];     // Mảng động
delete[] arr;                   // PHẢI dùng delete[]

// new với exception handling
Type* ptr = new (std::nothrow) Type;  // Trả về nullptr nếu lỗi
if (ptr == nullptr) {
    // Xử lý lỗi
}
```
---

## D. Con Trỏ Thông Minh (Smart Pointers)

**Định nghĩa:** Smart pointers tự động quản lý bộ nhớ theo RAII (Resource Acquisition Is Initialization).

### 1. std::unique_ptr (Sở hữu độc quyền)

**Đặc điểm:**
- Chỉ **một** `unique_ptr` sở hữu đối tượng tại một thời điểm
- Không thể copy, chỉ có thể move
- Overhead: Gần như 0 (same size as raw pointer)
- Tự động `delete` khi ra khỏi scope

#### Cú pháp

```cpp
#include <memory>
#include <iostream>

class Resource {
public:
    Resource() { std::cout << "Resource acquired\n"; }
    ~Resource() { std::cout << "Resource released\n"; }
    void use() { std::cout << "Using resource\n"; }
};

int main() {
    // Tạo unique_ptr (C++14+)
    auto ptr1 = std::make_unique<Resource>();
    ptr1->use();

    // Không thể copy
    // auto ptr2 = ptr1;  // LỖI: deleted copy constructor

    // Có thể move (chuyển quyền sở hữu)
    auto ptr2 = std::move(ptr1);  // ptr1 giờ là nullptr
    if (ptr1 == nullptr) {
        std::cout << "ptr1 is null after move\n";
    }
    ptr2->use();

    // Tự động delete khi ra khỏi scope
    return 0;
}
```

**Output:**
```
Resource acquired
Using resource
ptr1 is null after move
Using resource
Resource released
```
---

### 2. std::shared_ptr (Đồng sở hữu)

**Đặc điểm:**
- Nhiều `shared_ptr` có thể cùng sở hữu một đối tượng
- Sử dụng **reference counting** (đếm số chủ sở hữu)
- Đối tượng bị `delete` khi count về 0
- Overhead: 2 con trỏ (data + control block)

#### Cú pháp

```cpp
#include <memory>
#include <iostream>

class Data {
public:
    Data(int v) : value(v) {
        std::cout << "Data(" << value << ") created\n";
    }
    ~Data() {
        std::cout << "Data(" << value << ") destroyed\n";
    }
    int value;
};

int main() {
    std::shared_ptr<Data> ptr1 = std::make_shared<Data>(42);
    std::cout << "Count: " << ptr1.use_count() << "\n";  // 1

    {
        auto ptr2 = ptr1;  // Copy: tăng reference count
        std::cout << "Count: " << ptr1.use_count() << "\n";  // 2
        
        auto ptr3 = ptr1;
        std::cout << "Count: " << ptr1.use_count() << "\n";  // 3
    }  // ptr2, ptr3 ra khỏi scope → count giảm về 1

    std::cout << "Count: " << ptr1.use_count() << "\n";  // 1

    return 0;  // ptr1 ra khỏi scope → count về 0 → delete object
}
```

**Output:**
```
Data(42) created
Count: 1
Count: 2
Count: 3
Count: 1
Data(42) destroyed
```

---

### 3. std::weak_ptr (Quan sát không sở hữu)

**Đặc điểm:**
- Quan sát đối tượng do `shared_ptr` quản lý
- Không tăng reference count
- Dùng để phá vỡ circular references

#### Circular Reference Problem

```cpp
#include <memory>
#include <iostream>

class B;  // Forward declaration

class A {
public:
    std::shared_ptr<B> ptrB;
    ~A() { std::cout << "A destroyed\n"; }
};

class B {
public:
    std::shared_ptr<A> ptrA;  // Circular reference!
    ~B() { std::cout << "B destroyed\n"; }
};

int main() {
    auto a = std::make_shared<A>();
    auto b = std::make_shared<B>();
    
    a->ptrB = b;  // a → b
    b->ptrA = a;  // b → a (circular!)
    
    return 0;
    //  Cả a và b KHÔNG bị destroy → Memory leak!
}
```

#### Giải pháp: weak_ptr

```cpp
class A {
public:
    std::shared_ptr<B> ptrB;
    ~A() { std::cout << "A destroyed\n"; }
};

class B {
public:
    std::weak_ptr<A> ptrA;  // ✓ Dùng weak_ptr
    ~B() { std::cout << "B destroyed\n"; }
};

int main() {
    auto a = std::make_shared<A>();
    auto b = std::make_shared<B>();
    
    a->ptrB = b;
    b->ptrA = a;  // weak_ptr không tăng count
    
    return 0;
    // ✓ a và b được destroy đúng cách!
}
```

#### Sử dụng weak_ptr

```cpp
std::weak_ptr<Data> weak;

{
    auto shared = std::make_shared<Data>(42);
    weak = shared;  // Quan sát shared
    
    // Để truy cập, phải lock() để lấy shared_ptr tạm thời
    if (auto temp = weak.lock()) {
        std::cout << "Value: " << temp->value << "\n";
    } else {
        std::cout << "Object expired\n";
    }
}  // shared bị destroy

// Giờ weak.lock() sẽ trả về nullptr
if (auto temp = weak.lock()) {
    std::cout << "Still alive\n";
} else {
    std::cout << "Object expired\n";  // In dòng này
}
```

---

### Bảng So Sánh Smart Pointers

| Đặc điểm | unique_ptr | shared_ptr | weak_ptr |
|:---------|:-----------|:-----------|:---------|
| Quyền sở hữu | Độc quyền | Chia sẻ | Không sở hữu |
| Copy | Không |  Có |  Có |
| Move |  Có |  Có | Có |
| Overhead | ~0 bytes | ~16 bytes | ~16 bytes |
| Reference counting | Không | Có | Không tăng count |
| Use case | Default choice | Shared ownership | Phá circular ref |

**Quy tắc vàng:**
1. Mặc định dùng `unique_ptr`
2. Dùng `shared_ptr` khi thực sự cần shared ownership
3. Dùng `weak_ptr` để tránh circular references

---

## E. Lớp và Vòng Đời Đối Tượng

### 1. Constructor (Hàm Tạo)

**Định nghĩa:** Constructor khởi tạo đối tượng, thiết lập trạng thái ban đầu.

#### Các loại Constructor

```cpp
#include <iostream>
#include <string>

class Student {
private:
    std::string name;
    int age;
    double gpa;

public:
    // 1. Default constructor
    Student() : name("Unknown"), age(0), gpa(0.0) {
        std::cout << "Default constructor\n";
    }

    // 2. Parameterized constructor
    Student(const std::string& n, int a, double g) 
        : name(n), age(a), gpa(g) {
        std::cout << "Parameterized constructor\n";
    }

    // 3. Copy constructor
    Student(const Student& other) 
        : name(other.name), age(other.age), gpa(other.gpa) {
        std::cout << "Copy constructor\n";
    }

    // 4. Move constructor (C++11)
    Student(Student&& other) noexcept
        : name(std::move(other.name)), 
          age(other.age), 
          gpa(other.gpa) {
        std::cout << "Move constructor\n";
    }

    void print() const {
        std::cout << name << ", " << age << ", " << gpa << "\n";
    }
};

int main() {
    Student s1;                          // Default
    Student s2("An", 20, 3.8);          // Parameterized
    Student s3 = s2;                    // Copy
    Student s4 = std::move(s3);         // Move
    
    return 0;
}
```

#### Member Initializer List (Danh sách khởi tạo)

```cpp
// Cách KHÔNG nên (gán trong body)
Student(const std::string& n, int a) {
    name = n;  // Assignment, không phải initialization
    age = a;
}

// ✓ Cách NÊN (initializer list)
Student(const std::string& n, int a) 
    : name(n),  // Direct initialization
      age(a) {
}
```

**Lợi ích initializer list:**
- Hiệu quả hơn (tránh default construct rồi assign)
- Bắt buộc với const members và references
- Thứ tự khởi tạo theo thứ tự khai báo trong class

---

### 2. Destructor (Hàm Hủy)

**Định nghĩa:** Destructor dọn dẹp tài nguyên khi đối tượng kết thúc vòng đời.

```cpp
class FileHandler {
private:
    FILE* file;

public:
    FileHandler(const char* filename) {
        file = fopen(filename, "r");
        if (file) {
            std::cout << "File opened\n";
        }
    }

    ~FileHandler() {  // Destructor
        if (file) {
            fclose(file);
            std::cout << "File closed\n";
        }
    }

    // Prevent copying (rule of three/five)
    FileHandler(const FileHandler&) = delete;
    FileHandler& operator=(const FileHandler&) = delete;
};

int main() {
    FileHandler handler("data.txt");
    // ... sử dụng file
    return 0;
}  // Destructor tự động gọi, file được đóng
```

#### Virtual Destructor

**Quan trọng:** Khi xóa đối tượng dẫn xuất qua con trỏ lớp cơ sở:

```cpp
class Base {
public:
    virtual ~Base() {  // ✓ Virtual destructor
        std::cout << "Base destroyed\n";
    }
};

class Derived : public Base {
private:
    int* data;

public:
    Derived() : data(new int[100]) {
        std::cout << "Derived created\n";
    }

    ~Derived() override {
        delete[] data;
        std::cout << "Derived destroyed\n";
    }
};

int main() {
    Base* ptr = new Derived();
    delete ptr;  // ✓ Gọi cả Derived::~Derived() và Base::~Base()
    return 0;
}
```

**Nếu không có `virtual`:**
```cpp
class Base {
public:
    ~Base() {  // Không virtual
        std::cout << "Base destroyed\n";
    }
};

int main() {
    Base* ptr = new Derived();
    delete ptr;  // CHỈ gọi Base::~Base() → Memory leak!
    return 0;
}
```

---

### 3. Rule of Three/Five/Zero

#### Rule of Three (C++98)

Nếu class cần một trong ba, thường cần cả ba:
1. Destructor
2. Copy constructor
3. Copy assignment operator

#### Rule of Five (C++11+)

Thêm:
4. Move constructor
5. Move assignment operator

#### Rule of Zero (Khuyến nghị)

**Tốt nhất: KHÔNG tự quản lý tài nguyên**, dùng RAII containers:

```cpp
// Cách cũ (phải implement rule of five)
class OldWay {
private:
    int* data;
    size_t size;

public:
    OldWay(size_t s) : size(s), data(new int[s]) {}
    ~OldWay() { delete[] data; }
    
    // Phải implement copy constructor, copy assignment,
    // move constructor, move assignment...
};

// ✓ Cách mới (rule of zero)
class ModernWay {
private:
    std::vector<int> data;  // Tự động quản lý memory!

public:
    ModernWay(size_t s) : data(s) {}
    // Không cần destructor, compiler tự generate!
};
```

---

## F. Demo Project

Xem thư mục [Demo/](Demo/) để có ví dụ thực tế về:
- Con trỏ thô (raw pointers)
- unique_ptr
- shared_ptr
- weak_ptr
- So sánh hiệu suất và an toàn

**Build và chạy:**
```bash
cd Demo
./run.sh
```

---

## G. Bảng Tóm Tắt

### Nguyên tắc OOP

| Nguyên tắc | Ý nghĩa | Từ khóa liên quan |
|:-----------|:--------|:------------------|
| Encapsulation | Gom dữ liệu + phương thức, kiểm soát truy cập | `private`, `protected`, `public` |
| Inheritance | Tái sử dụng code, quan hệ "is-a" | `: public Base`, `protected`, `private` |
| Polymorphism | Cùng interface, hành vi khác nhau | `virtual`, `override`, `final` |
| Abstraction | Ẩn chi tiết, chỉ hiện giao diện | `= 0` (pure virtual) |

### Compiler Flags

```bash
# Debug build
g++ -std=c++17 -Wall -Wextra -g -O0 main.cpp -o app

# Release build
g++ -std=c++17 -Wall -Wextra -O3 -DNDEBUG main.cpp -o app

# With sanitizers (phát hiện lỗi memory/undefined behavior)
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address,undefined main.cpp -o app
```

**Flags quan trọng:**
- `-std=c++17`: Chọn chuẩn C++17
- `-Wall -Wextra`: Bật cảnh báo
- `-g`: Thêm debug info
- `-O0`: Không optimize (debug), `-O3`: Optimize tối đa (release)
- `-fsanitize=address`: Phát hiện memory errors
- `-fsanitize=undefined`: Phát hiện undefined behavior

---

## Tài liệu tham khảo

- [C++ Reference](https://en.cppreference.com/)
- [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/)

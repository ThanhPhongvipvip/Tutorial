#include <iostream>
#include <memory>

class Student {
public:
    std::string name;
    int age;
    
    Student(std::string n, int a) : name(n), age(a) {
        std::cout << "Created: " << name << "\n";
    }
    
    ~Student() {
        std::cout << "Destroyed: " << name << "\n";
    }
};

int main() {
    // Cấp phát bằng make_unique
    auto s1 = std::make_unique<Student>("Binh", 21);
    
    // smart pointer
    std::cout << "Name: " << s1->name << ", Age: " << s1->age << "\n";
    
    // Tự động delete khi ra khỏi scope, không cần delete thủ công
    
    return 0;
}

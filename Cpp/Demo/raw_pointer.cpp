#include <iostream>

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
    // Cấp phát bằng new
    Student* s1 = new Student("An", 20);
    
    // raw pointer
    std::cout << "Name: " << s1->name << ", Age: " << s1->age << "\n";
    
    // Phải nhớ delete
    delete s1;
    
    return 0;
}

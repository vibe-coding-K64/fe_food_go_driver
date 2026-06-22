# Cấu trúc thư mục dự án - Food Go Driver

Dự án frontend Flutter cho ứng dụng tài xế giao hàng.

---

## Cấu trúc tổng thể

```
be-foodgo/
│
├── .mvn/                              # Maven wrapper
├── .vscode/                           # Cấu hình VS Code
├── docs/                              # Tài liệu dự án
│   ├── project_structure.md           # Tài liệu này
├── src/                               # Source code
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/be_foodgo/
│   │   │       ├── BeFoodgoApplication.java   # Entry point
│   │   │       ├── config/                   # Cấu hình
│   │   │       ├── constant/                 # Enum & hằng số
│   │   │       ├── controller/               # REST API
│   │   │       ├── dto/                     # Data Transfer Object
│   │   │       ├── exception/               # Xử lý lỗi tập trung
│   │   │       ├── model/                   # Entity model
│   │   │       ├── repository/              # Data access layer
│   │   │       ├── seeder/                  # Khởi tạo dữ liệu mẫu
│   │   │       └── service/                 # Logic nghiệp vụ
│   │   └── resources/
│   │       ├── application.properties        # Cấu hình Spring
│   │       ├── static/                      # Static files
│   │       └── templates/                   # Template files
│   └── test/                               # Unit tests
│       └── java/com/example/be_foodgo/
│
├── pom.xml                             # Maven dependencies
├── mvnw / mvnw.cmd                     # Maven wrapper scripts
├── .gitignore                          # Git ignore
└── README.md                           # Hướng dẫn sử dụng
```

---

## Kiến trúc phân lớp (Layered Architecture)

```
Controller
    │ gọi
    ▼
Service
    │ gọi
    ▼
Repository
    │ gọi
    ▼
REST API (Backend)
```

### Chi tiết từng lớp

| Package         | Chức năng                                                                          |
| --------------- | ---------------------------------------------------------------------------------- |
| `config`        | Cấu hình hệ thống: API, Security, CORS...                                          |
| `constant`      | Enum (trạng thái, role...) và hằng số dùng chung toàn hệ thống                    |
| `controller`    | REST API endpoints. Nhận request từ client, trả response. Không chứa logic nghiệp vụ.    |
| `dto`           | Data Transfer Object. Đóng gói dữ liệu gửi/nhận qua API (request/response).             |
| `exception`     | Global Exception Handler. Xử lý lỗi tập trung, trả về message thống nhất cho client.      |
| `bloc`          | Business Logic Component. Quản lý trạng thái UI và xử lý sự kiện.                      |
| `repository`    | Định nghĩa interface cho tầng data. Triển khai gọi API, WebSocket.                      |
| `datasource`    | Nguồn dữ liệu: REST API, WebSocket STOMP.                                             |
| `model`         | Data model/entity mapping.                                                          |
| `service`       | Logic nghiệp vụ. Xử lý các tác vụ nghiệp vụ phức tạp, gọi repository để truy vấn dữ liệu. |

### Mối quan hệ giữa các lớp

```
Client (HTTP Request / WebSocket)
       │
       ▼
┌─────────────────┐
│   BLoC           │  Quản lý trạng thái UI, xử lý sự kiện
└────────┬────────┘
         │ call
         ▼
┌─────────────────┐
│    Repository    │  Interface cho data access
└────────┬────────┘
         │ call
         ▼
┌─────────────────┐
│   DataSource     │  REST API, WebSocket STOMP
└────────┬────────┘
         │
         ▼
  Backend API
```

---

## Quy tắc đặt tên

| Loại              | Quy tắc                | Ví dụ                          |
| ----------------- | ---------------------- | ------------------------------ |
| Class Java        | PascalCase             | `UserController.java`          |
| Interface         | PascalCase + suffix    | `UserService.java`              |
| Method            | camelCase              | `getUserById()`                 |
| Variable          | camelCase              | `userId`, `isActive`            |
| Package           | lowercase              | `controller`, `dto`            |
| Enum              | PascalCase             | `OrderStatus.java`              |
| Enum constant     | SCREAMING_SNAKE_CASE   | `PENDING`, `COMPLETED`          |
| Database field  | camelCase              | `createdAt`, `userId`           |

---

## Quy tắc commit Git

| Prefix | Môi trường sử dụng                                    |
| ------ | ----------------------------------------------------- |
| `feat` | Thêm chức năng mới                                     |
| `fix`  | Sửa lỗi                                               |
| `docs` | Cập nhật tài liệu                                     |
| `refactor` | Tái cấu trúc code, không thay đổi chức năng          |
| `chore` | Cập nhật phụ thuộc, build script                      |

Áp dụng format: `<type>: <short description>`

Ví dụ:
- `feat: implement JWT authentication`
- `fix: resolve token validation bug`

---

## GITHUB (BẮT BUỘC)

### Repository

- Mỗi nhóm tạo **01 repository** trên GitHub
- Repository phải:
  - **Public** (hoặc Private nhưng add giảng viên)
  - Có file `README.md` mô tả:
    - Tên đề tài
    - Thành viên nhóm
    - Mô tả chức năng hệ thống
    - Hướng dẫn chạy project
    - Link Swagger UI

### Quy định chia nhánh

#### 1. `main`

- Chứa code ổn định, production-ready
- Chỉ merge từ `develop`
- **Không commit trực tiếp**

#### 2. `dev`

- Nhánh phát triển chính
- Merge từ các `feature/*` hoặc `defect/*`
- Dùng để test tích hợp trước khi lên `main`

#### 3. `feature/xxx`

- Phát triển tính năng mới
- Ví dụ: `feature/authentication`
- Sau khi hoàn thành, tạo **Pull Request** vào `develop`

#### 4. `defect/xxx`

- Sửa lỗi
- Ví dụ: `defect/login-bug`

### Quy trình làm việc chuẩn

1. Tạo branch từ `develop`
2. Code + commit
3. Push lên GitHub
4. Tạo **Pull Request (PR)**
5. Thành viên khác review
6. Merge vào `develop`
7. Khi hoàn chỉnh, merge `develop` → `main`

> **Lưu ý:** Không được commit trực tiếp vào `main`

### Quy chuẩn commit message

Áp dụng format: `<type>: <short description>`

Ví dụ:
- `feat: implement JWT authentication`
- `fix: resolve token validation bug`

---

## Chú thích

- File `.gitkeep` trong mỗi package đảm bảo Git tracking cả khi package chưa có file nào.

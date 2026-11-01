# 📚 DAILY YOU – TH3 LEARNING ENGLISH

## 1. Giới thiệu dự án

**Daily You – TH3 Learning English** là dự án phát triển ứng dụng học tiếng Anh dựa trên mã nguồn Daily You (Flutter).

Dự án hướng đến việc hỗ trợ người học xây dựng thói quen học tiếng Anh mỗi ngày, theo dõi tiến độ học tập và luyện tập phát âm thông qua các tính năng có ứng dụng AI.

### Mục tiêu dự án

- Xây dựng thói quen học tiếng Anh hằng ngày.
- Theo dõi thời gian học tập, mục tiêu và tiến độ cá nhân.
- Hỗ trợ luyện tập và đánh giá phát âm tiếng Anh.
- Cung cấp điểm số, phản hồi và gợi ý cải thiện phát âm.
- Phát triển các chức năng hỗ trợ học tập và tương tác.

### Công nghệ chính

- **Framework:** Flutter
- **Programming Language:** Dart
- **Version Control:** Git & GitHub

---

## 2. Phân chia thành viên

| Thành viên | Checklist tương ứng |
|---|---|
| Đào Hà Thu (TV1) | Checklist 1 – Thiết kế cơ sở dữ liệu |
| Mạnh Đức (TV2) | Checklist 2 – Theo dõi tiến độ học tập |
| Kim Anh (TV3) | Checklist 6 – Nhắc nhở và giao diện tiến độ |
| Dũng (TV4) | Checklist 3 – Speech Recognition API và xử lý âm thanh |
| Trung (TV5) | Checklist 4, 5 – Đánh giá phát âm và phản hồi kết quả |

**Checklist 7 – Kiểm thử:** Tất cả thành viên cùng thực hiện.

---

## 3. Quy tắc làm việc với GitHub

Repository chính của nhóm:

**Daily_You_TH3_learningenglish**

Repository: https://github.com/Maya0612/Daily_You_TH3_learningenglish

### 3.1. Quy tắc sử dụng nhánh (Branch)

Nhóm sử dụng các nhánh sau:

| Nhánh | Mục đích |
|---|---|
| `main` | Chứa phiên bản code chính thức của dự án |
| `feature/tv1-database` hoặc `feature/hathu`  | Nhánh làm việc của TV1 |
| `feature/tv2-progress` hoặc `feature/manhduc` | Nhánh làm việc của TV2 |
| `feature/tv3-reminder-ui` hoặc `feature/kimqanh` | Nhánh làm việc của TV3 |
| `feature/tv4-audio-api` hoặc `feature/tiendung`| Nhánh làm việc của TV4 |
| `feature/tv5-pronunciation` hoặc `feature/ductrung`| Nhánh làm việc của TV5 |

**Quy định:**

1. Mỗi thành viên chỉ làm việc trên nhánh riêng của mình.
2. Không chỉnh sửa trực tiếp trên nhánh `main`.
3. Trước khi làm việc phải cập nhật code mới nhất từ `main`.
4. Khi hoàn thành chức năng, thành viên phải tự kiểm thử trước khi tạo Pull Request.
5. Mọi thay đổi phải được đưa lên GitHub thông qua Pull Request.
6. Thành viên chịu trách nhiệm xử lý conflict trong phần code của mình.
7. Sau khi Pull Request không còn conflict và đã kiểm thử thành công, thành viên thực hiện Merge vào `main`.

### MỖI THÀNH VIÊN PHẢI CHỊU TRÁCH NHIỆM NẾU MERGE XONG MÀ ẢNH HƯỞNG TỚI DỰ ÁN (TỨC ẢNH HƯỞNG TỚI THÀNH VIÊN KHÁC HOẶC LÀM DỰ ÁN LỖI )

---

## 4. Hướng dẫn Clone dự án về máy

 1. Mở Terminal hoặc CMD VÀ Clone repository

Chạy lệnh:

```bash
git clone https://github.com/Maya0612/Daily_You_TH3_learningenglish.git
```

2. Di chuyển vào thư mục dự án

```bash
cd Daily_You_TH3_learningenglish
```

3. Mở dự án bằng VS Code

```bash
code .
```

4. Cài đặt các thư viện Flutter

```bash
flutter pub get
```

Sau khi cài đặt thành công, có thể chạy ứng dụng bằng:

```bash
flutter run
```

---

## 5. Hướng dẫn Pull – Cập nhật code mới nhất

**Trước khi bắt đầu làm việc hoặc chỉnh sửa code, cần cập nhật phiên bản mới nhất từ `main`.**

### Bước 1. Kiểm tra nhánh hiện tại

```bash
git branch
```

### Bước 2. Chuyển về nhánh main

```bash
git checkout main
```

### Bước 3. Lấy code mới nhất từ GitHub

```bash
git pull origin main
```

### Bước 4. Chuyển về nhánh cá nhân

Ví dụ TV2:

```bash
git checkout feature/tv2-progress
```

### Bước 5. Cập nhật code mới từ main vào nhánh cá nhân

```bash
git merge main
```

Nếu có conflict, xử lý theo hướng dẫn tại mục 8.

---



## 6. Hướng dẫn Push – Đẩy code lên GitHub

Sau khi hoàn thành một phần chức năng, thành viên thực hiện:

### Bước 1. Kiểm tra nhánh đang làm việc

```bash
git branch
```

Đảm bảo dấu `*` đang nằm ở nhánh cá nhân, không phải `main`.

### Bước 2. Kiểm tra các file đã thay đổi

```bash
git status
```

### Bước 3. Thêm các file cần cập nhật

```bash
git add .
```

### Bước 4. Commit code

```bash
git commit -m "Mo ta noi dung da thay doi"
```

Ví dụ:

```bash
git commit -m "Implement study progress"
```

### Bước 5. Push code lên nhánh cá nhân

Ví dụ TV2:

```bash
git push origin feature/tv2-progress
```

**Lưu ý:**

- Chỉ push lên nhánh cá nhân.
- Không push trực tiếp lên `main`.
- Không sử dụng `git push --force` khi chưa trao đổi với nhóm.

---



## 7. Hướng dẫn tạo Pull Request và Merge vào main

Sau khi push code thành công:

### Bước 1. Truy cập repository trên GitHub

https://github.com/Maya0612/Daily_You_TH3_learningenglish

### Bước 2. Tạo Pull Request

1. Chọn tab `Pull requests`.
2. Nhấn `New pull request`.
3. Thiết lập:
   - **Base:** `main`
   - **Compare:** Nhánh cá nhân của bạn.
4. Kiểm tra danh sách file thay đổi.
5. Đặt tiêu đề mô tả chức năng đã hoàn thành.
6. Nhấn `Create pull request`.

Ví dụ:

- Base: `main`
- Compare: `feature/tv2-progress`

### Bước 3. Kiểm tra Pull Request

Thành viên cần kiểm tra:

- Đã chọn đúng nhánh cá nhân chưa?
- Đã chọn đúng nhánh đích `main` chưa?
- Các file thay đổi có đúng với chức năng phụ trách không?
- Chức năng đã được kiểm thử và hoạt động bình thường chưa?
- Có phát sinh conflict không?

### Bước 4. Merge vào main

Nếu Pull Request không còn conflict và chức năng đã được kiểm thử thành công:

1. Nhấn `Merge pull request`.
2. Chọn `Confirm merge`.
3. Kiểm tra code đã được cập nhật vào nhánh `main`.

**Mỗi thành viên chịu trách nhiệm hoàn thành Pull Request và thực hiện Merge phần code của mình sau khi đáp ứng các điều kiện trên.**

---



## 8. Hướng dẫn tự xử lý Conflict

### 8.1. Conflict là gì?

Conflict xảy ra khi Git không thể tự động kết hợp các thay đổi, thường do nhiều nhánh cùng chỉnh sửa một đoạn trong cùng một file.

Khi xảy ra conflict, thành viên cần tự xử lý phần code thuộc chức năng mình phụ trách.

### 8.2. Cách xử lý conflict bằng VS Code

**Bước 1. Cập nhật code mới nhất từ main**

```bash
git fetch origin
```

**Bước 2. Chuyển sang nhánh cá nhân**

Ví dụ:

```bash
git checkout feature/tv2-progress
```

**Bước 3. Kết hợp code mới nhất từ main**

```bash
git merge origin/main
```

Nếu xảy ra conflict, Git sẽ thông báo các file đang có xung đột.

**Bước 4. Mở các file bị conflict bằng VS Code**

Trong file có thể xuất hiện các ký hiệu:

```text
<<<<<<< HEAD
Code trên nhánh cá nhân
=======
Code từ nhánh main
>>>>>>> origin/main
```

Ý nghĩa:

- `<<<<<<< HEAD`: Phần code hiện tại trên nhánh cá nhân.
- `=======`: Dấu phân cách hai phần code.
- `>>>>>>> origin/main`: Phần code từ nhánh main.

**Bước 5. Tự kiểm tra và chỉnh sửa**

Thành viên cần đọc cả hai phần code, xác định nội dung nào cần giữ hoặc kết hợp.

Không xóa tùy tiện một phần code khi chưa hiểu chức năng của nó.

Sau khi xử lý xong:

- Xóa các dấu `<<<<<<<`, `=======`, `>>>>>>>`.
- Đảm bảo code hoàn chỉnh và đúng logic.
- Lưu file.

**Bước 6. Đánh dấu conflict đã được xử lý**

```bash
git add .
```

**Bước 7. Commit phần đã xử lý**

```bash
git commit -m "Resolve merge conflicts"
```

**Bước 8. Kiểm thử lại chức năng**

Chạy ứng dụng và kiểm tra chức năng của mình hoạt động bình thường.

**Bước 9. Push nhánh cá nhân lên GitHub**

```bash
git push origin feature/tv2-progress
```

Sau đó quay lại Pull Request trên GitHub để kiểm tra trạng thái conflict.

Nếu không còn conflict, thành viên tiếp tục thực hiện Merge vào `main`.

### 8.3. Nếu không xử lý được conflict

- Không cố xóa code để hết thông báo conflict.
- Không sử dụng lệnh force push.
- Trao đổi với thành viên sở hữu phần code liên quan.
- Chỉ tiếp tục Merge khi đã hiểu và kiểm tra được phần code sau khi xử lý.

---




## 9. Quy định kiểm thử chức năng

**TẤT CẢ THÀNH VIÊN BẮT BUỘC TỰ KIỂM THỬ CHỨC NĂNG DO MÌNH PHÁT TRIỂN.**

Trước khi tạo Pull Request, mỗi thành viên cần:

1. Chạy thử chức năng trên máy cá nhân.
2. Kiểm tra các trường hợp hoạt động bình thường.
3. Kiểm tra các trường hợp nhập dữ liệu sai hoặc thiếu dữ liệu (nếu có).
4. Kiểm tra chức năng có hoạt động đúng với các phần liên quan không.
5. Sửa các lỗi phát hiện được trước khi gửi Pull Request.
6. Chuẩn bị ảnh chụp màn hình hoặc video minh chứng chức năng hoạt động.

Không tạo Pull Request khi chức năng chưa được kiểm thử.

### Kiểm thử toàn bộ ứng dụng

Sau khi các thành viên hoàn thành và Merge code, cả nhóm phối hợp kiểm thử luồng hoạt động tổng thể của ứng dụng để phát hiện lỗi tích hợp.

---

## 10. Một số lệnh Git thường dùng

| Lệnh | Chức năng |
|---|---|
| `git status` | Kiểm tra trạng thái file |
| `git branch` | Xem các nhánh |
| `git branch -a` | Xem tất cả nhánh local và remote |
| `git checkout main` | Chuyển sang nhánh main |
| `git checkout <branch>` | Chuyển sang nhánh chỉ định |
| `git fetch origin` | Lấy thông tin cập nhật từ GitHub |
| `git pull origin main` | Kéo code mới nhất từ main |
| `git add .` | Thêm các thay đổi vào staging |
| `git commit -m "message"` | Lưu thay đổi vào lịch sử Git |
| `git push origin <branch>` | Đẩy code lên nhánh chỉ định |
| `git merge origin/main` | Kết hợp code mới nhất từ main vào nhánh hiện tại |
| `git log --oneline` | Xem lịch sử commit |

---

## 11. Nguyên tắc chung

1. Mỗi thành viên chịu trách nhiệm đối với chức năng được phân công.
2. Làm việc trên nhánh cá nhân, không chỉnh sửa trực tiếp `main`.
3. Thường xuyên Pull code mới nhất để tránh xung đột.
4. Tự kiểm thử chức năng trước khi tạo Pull Request.
5. Tự xử lý conflict trong phạm vi code mình phụ trách.
6. Không xóa hoặc sửa code của thành viên khác khi chưa trao đổi.
7. Không Merge code khi chức năng chưa hoạt động hoặc chưa được kiểm thử.
8. Không commit API key, mật khẩu hoặc thông tin bí mật lên repository.
9. Nếu gặp lỗi ảnh hưởng đến phần việc của thành viên khác, cần trao đổi trước khi chỉnh sửa.

**Mục tiêu chung: Mỗi thành viên hoàn thành, kiểm thử và tích hợp tốt chức năng của mình để tạo thành một ứng dụng học tiếng Anh hoàn chỉnh.**
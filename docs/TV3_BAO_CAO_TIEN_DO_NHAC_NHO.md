# BÁO CÁO NGHIỆM THU CHECKLIST 6: NHẮC NHỞ HẰNG NGÀY VÀ GIAO DIỆN TIẾN ĐỘ
**Dự án:** Daily You – TH3 Learning English  
**Người thực hiện:** Kim Anh (Thành viên 3 - TV3: Daily Reminder & Progress UI/Logic)  
**Nhánh làm việc (Branch):** `feature/tv3-reminder-ui` (hoặc `feature/kimqanh`)  
**Ngày hoàn thành:** 02/11/2026  

---

## TỔNG HỢP TIẾN ĐỘ CHECKLIST 6

| STT | Nội dung tiêu chí Checklist 6 | Trạng thái | Vị trí file trong dự án |
|:---:|---|:---:|---|
| **1** | Định nghĩa Data Model tiến độ & cấu trúc tuần phối hợp với TV2 | **ĐÃ HOÀN THÀNH** | `lib/models/learning_progress.dart` |
| **2** | Service lập lịch và quản lý Local Notification linh hoạt | **ĐÃ HOÀN THÀNH** | `lib/services/daily_reminder_service.dart` |
| **3** | State Management (Provider) kết nối CSDL và tính toán Streak tự động | **ĐÃ HOÀN THÀNH** | `lib/providers/learning_progress_provider.dart` |
| **4** | Giao diện Dashboard Tổng quan Tiến độ trực quan (Streak, Circular Progress) | **ĐÃ HOÀN THÀNH** | `lib/pages/learning_progress_page.dart` |
| **5** | Biểu đồ cột 7 ngày trong tuần responsive (Weekly Progress Chart) | **ĐÃ HOÀN THÀNH** | `lib/widgets/weekly_progress_chart.dart` |
| **6** | Hộp thoại Cài đặt Nhắc nhở hằng ngày (TimePicker, Switch, Goal Chips) | **ĐÃ HOÀN THÀNH** | `lib/widgets/learning_reminder_dialog.dart` |
| **7** | Kịch bản kiểm thử (Test Plan), Unit Tests, Widget Tests và minh chứng | **ĐÃ HOÀN THÀNH** | `test/providers/learning_progress_provider_test.dart`<br>`test/pages/learning_progress_page_test.dart` |

---

## 1. KIẾN TRÚC & MÔ HÌNH DỮ LIỆU TIẾN ĐỘ (HỢP TÁC VỚI TV2)

### 1.1 Khái niệm & Luồng truyền dữ liệu
Dữ liệu tiến độ học tập được xây dựng trên nguyên tắc **phản ứng thời gian thực (Reactive Data Binding)**:
- **Tầng lưu trữ:** SQLite CSDL thông qua `PracticeHistoryDao` (TV1) và `PronunciationResultDao`.
- **Tầng tổng hợp:** `LearningProgressProvider` (TV3 kết nối với TV2) tính toán các chỉ số:
  1. **Tổng thời gian học hôm nay:** Tổng số giây luyện tập có trạng thái `COMPLETED`.
  2. **Chuỗi ngày học liên tục (Streak):** Thuật toán duyệt ngược các ngày liên tiếp có ít nhất 1 bài học hoàn thành bắt đầu từ hôm nay hoặc hôm qua.
  3. **Mục tiêu học tập hằng ngày:** Cho phép học viên tùy biến (10, 15, 20, 30, 45, 60 phút).
  4. **Tỷ lệ hoàn thành (%):** Tính toán và clamp chuẩn hóa từ 0% đến 100%.
  5. **Thống kê 7 ngày gần nhất:** Tổng thời gian học tuần, ngày học nhiều nhất (Best Day).
  6. **Lịch sử gần đây:** 5 bài luyện phát âm gần nhất kèm thời lượng và trạng thái.

### 1.2 Chi tiết Model trong mã nguồn
- Tệp: [`lib/models/learning_progress.dart`](file:///d:/Documents/mobile/Daily_You_TH3_learningenglish/lib/models/learning_progress.dart)
  + `DayProgressItem`: Dữ liệu của 1 ngày trong biểu đồ tuần (nhãn thứ, số giây học, đạt mục tiêu hay chưa).
  + `WeeklyProgressData`: Dữ liệu tổng hợp tuần (danh sách 7 ngày, tổng số phút tuần, trung bình ngày, ngày học nhiều nhất).
  + `DailyLearningProgress`: Thực thể toàn diện cung cấp trạng thái cho UI Dashboard.
  + `ProgressViewState`: Enum quản lý trạng thái màn hình (`initial`, `loading`, `loaded`, `empty`, `error`).

---

## 2. SERVICE QUẢN LÝ THÔNG BÁO CỤC BỘ (LOCAL NOTIFICATION SERVICE)

### 2.1 Đặc tả kỹ thuật
- Tệp: [`lib/services/daily_reminder_service.dart`](file:///d:/Documents/mobile/Daily_You_TH3_learningenglish/lib/services/daily_reminder_service.dart)
- Thư viện tích hợp: `flutter_local_notifications: ^22.3.1` và `timezone: 0.11.1`.
- **Kênh thông báo (Notification Channel):**
  + Channel ID: `daily_english_learning_reminder`
  + Tên kênh: `Nhắc nhở học tiếng Anh`
  + Mức độ ưu tiên: `Importance.high`, `Priority.high`
  + Biểu tượng: `@drawable/ic_notification`
- **Cơ chế lặp lịch:** Sử dụng `zonedSchedule` kèm cờ `matchDateTimeComponents: DateTimeComponents.time` giúp thông báo lặp lại chính xác tại mốc giờ đã cài mỗi ngày.
- **Xử lý hủy và cập nhật lịch:** Tự động gọi `cancel(id: 1001)` trước khi lập lịch mới hoặc khi người dùng gạt tắt công tắc.
- **Tính năng thử nghiệm:** Cung cấp hàm `sendTestNotification()` để người dùng có thể kích hoạt thông báo ngay lập tức và xem hiển thị trên khay thông báo Android/iOS.

---

## 3. STATE MANAGEMENT & BINDING DỮ LIỆU THỜI GIAN THỰC

### 3.1 `LearningProgressProvider`
- Tệp: [`lib/providers/learning_progress_provider.dart`](file:///d:/Documents/mobile/Daily_You_TH3_learningenglish/lib/providers/learning_progress_provider.dart)
- Kế thừa `ChangeNotifier`, đăng ký Singleton:
  + Cung cấp API `recordCompletedSession(PracticeHistory session)`: Khi TV4/TV5 hoàn tất phiên chấm phát âm AI, gọi trực tiếp hàm này để UI Dashboard tự động cập nhật ngay lập tức chỉ số Streak và thời gian học mà không cần reload ứng dụng.
  + Hỗ trợ xử lý đầy đủ 4 trạng thái:
    * `ProgressViewState.loading`: Đang tải dữ liệu.
    * `ProgressViewState.empty`: Người học mới chưa có phiên học nào -> hiển thị giao diện kích hoạt chuỗi học tập đầu tiên.
    * `ProgressViewState.error`: Xử lý lỗi CSDL hoặc đọc file kèm nút Thử lại (Retry).
    * `ProgressViewState.loaded`: Dữ liệu sẵn sàng, hỗ trợ kéo xuống để làm mới (Pull-to-refresh).

---

## 4. GIAO DIỆN NGƯỜI DÙNG (DASHBOARD & SETTINGS UI)

### 4.1 Màn hình Tổng quan Tiến độ (Progress Overview Screen)
- Tệp: [`lib/pages/learning_progress_page.dart`](file:///d:/Documents/mobile/Daily_You_TH3_learningenglish/lib/pages/learning_progress_page.dart)
- Các thành phần nổi bật:
  1. **Card Streak ngọn lửa (Flame Banner):** Nổi bật với gradient màu cam, biểu tượng ngọn lửa tỏa sáng, số ngày streak và huy hiệu kỷ lục cá nhân.
  2. **Card Vòng tròn tiến độ (Circular Progress Indicator):** Vòng tròn bo tròn đầu (StrokeCap.round), màu xanh ngọc (Emerald Green) khi hoàn thành mục tiêu, hiển thị tỷ lệ % ở tâm và nút kêu gọi hành động "Luyện phát âm ngay".
  3. **Grid 3 Thống kê nhanh:** Thời gian học hôm nay, Số bài đã hoàn thành, Điểm phát âm trung bình.
  4. **Biểu đồ cột tiến độ 7 ngày:** Tự động điều chỉnh tỷ lệ cột, làm nổi bật ngày hôm nay với viền vàng ánh kim.
  5. **Danh sách phiên luyện tập gần đây:** Hiển thị icon theo loại hoạt động (phát âm, nói, nghe), thời lượng bài học và nhãn hoàn thành.

### 4.2 Hộp thoại Cài đặt Nhắc học (Reminder & Goal Dialog)
- Tệp: [`lib/widgets/learning_reminder_dialog.dart`](file:///d:/Documents/mobile/Daily_You_TH3_learningenglish/lib/widgets/learning_reminder_dialog.dart)
- Gồm:
  + Switch bật/tắt nhận thông báo.
  + Nút chọn giờ hiển thị dạng 24 giờ trực quan (`showTimePicker`).
  + Các Chip lựa chọn mục tiêu học tập (10, 15, 20, 30, 45, 60 phút/ngày).
  + Tùy chọn thông minh: "Chỉ nhắc khi chưa hoàn thành mục tiêu hôm nay".
  + Nút "Bắn thông báo thử nghiệm ngay" kèm thông báo phản hồi nhanh (SnackBar).

---

## 5. KẾT QUẢ KIỂM THỬ (AUTOMATED TESTING & VERIFICATION)

Đã chạy thành công 100% các bộ kiểm thử tự động với lệnh `flutter test`:

### 5.1 Unit Tests Provider & Thuật toán tính Streak
- Tệp: [`test/providers/learning_progress_provider_test.dart`](file:///d:/Documents/mobile/Daily_You_TH3_learningenglish/test/providers/learning_progress_provider_test.dart)
- Kết quả: **5/5 tests passed**
  * `DailyLearningProgress calculates percentages and remaining minutes correctly`: PASS
  * `DailyLearningProgress clamps percentage at 100% and marks goal achieved`: PASS
  * `Initial state with new user triggers ProgressViewState.empty`: PASS
  * `Recording completed sessions updates today time, streak and chart`: PASS
  * `Updating daily goal modifies provider state and recalculates percentage`: PASS

### 5.2 Widget Tests Giao diện Responsive & Trạng thái UI
- Tệp: [`test/pages/learning_progress_page_test.dart`](file:///d:/Documents/mobile/Daily_You_TH3_learningenglish/test/pages/learning_progress_page_test.dart)
- Kết quả: **3/3 tests passed**
  * `WeeklyProgressChart Widget Tests Renders 7 daily bars and summary`: PASS
  * `LearningProgressPage Widget Tests Renders empty state when user has no practice records`: PASS
  * `LearningProgressPage Widget Tests Responsive rendering on tablet / large screen (768x1024)`: PASS

# 🎨 NGUYÊN TẮC UI VÀ HƯỚNG DẪN TÍCH HỢP GIAO DIỆN HỌC TIẾNG ANH
> **Dự án:** Daily You – TH3 Learning English  
> **Áp dụng cho:** Tất cả các thành viên (TV1, TV2, TV3, TV4, TV5)

---

## 1. Mục đích tài liệu

Tài liệu này chuẩn hóa quy chuẩn giao diện (UI) và kiến trúc widget trên toàn bộ ứng dụng, nhằm:
1. Tránh triệt để lỗi xung đột giao diện, đặc biệt là lỗi màn hình đỏ **`No MaterialLocalizations found`**.
2. Cung cấp **màn hình mẫu (base template) hoàn chỉnh** đã tích hợp sẵn vào ứng dụng: [`lib/pages/practice_speech_page.dart`](file:///C:/Users/HP/Desktop/Daily_You_TH3_learningenglish/lib/pages/practice_speech_page.dart).
3. Hướng dẫn chi tiết vị trí và cách **TV4** (Ghi âm / Speech API) và **TV5** (Chấm điểm phát âm) gắn code của mình vào giao diện chung mà không làm vỡ app.

---

## 2. Quy tắc Vàng về Kiến trúc UI (Bắt buộc tuân thủ)

### ❌ QUY TẮC 1: TUYỆT ĐỐI KHÔNG DÙNG LỒNG `Scaffold` VÀ `AppBar` Ở TRANG CON
* **Nguyên nhân:** Toàn bộ ứng dụng Daily You được bọc ngoài bởi layout cha [`MobileScaffold`](file:///C:/Users/HP/Desktop/Daily_You_TH3_learningenglish/lib/layouts/mobile_scaffold.dart). Layout cha này đã tự động dựng sẵn:
  - Thanh tiêu đề trên cùng (`AppBar`) cho cả Desktop, Tablet và Mobile.
  - Thanh điều hướng bên trái (`NavigationRail` / Sidebar) trên Desktop/Tablet.
  - Thanh điều hướng bên dưới (`NavigationBar`) trên Mobile.
* **Hậu quả nếu vi phạm:** Nếu một trang con (như `LearningProgressPage`, `PracticeSpeechPage`) khai báo thêm `Scaffold` hoặc `AppBar` bên trong, hệ thống sẽ bị lỗi lồng Localizations và gây sập giao diện với màn hình đỏ `No MaterialLocalizations found`.
* **Cách viết ĐÚNG:** Trang con phải trả về một widget gốc là `Column` gồm:
  - Header row: Tiêu đề trang + Widget chuyển tài khoản [`UserProfileBar`](file:///C:/Users/HP/Desktop/Daily_You_TH3_learningenglish/lib/widgets/user_profile_bar.dart) + Action buttons.
  - `const Divider(height: 1)`
  - `Expanded(child: ListView(...))` chứa nội dung cuộn.

```dart
// ✅ CẤU TRÚC CHUẨN CỦA MỌI TRANG CON:
class MyFeaturePage extends StatelessWidget {
  const MyFeaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // 1. Header trang
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiêu đề chức năng',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const UserProfileBar(isCard: false), // Nút đổi tài khoản học viên
            ],
          ),
        ),
        const Divider(height: 1),

        // 2. Nội dung cuộn chính
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Các Card chức năng đặt tại đây...
            ],
          ),
        ),
      ],
    );
  }
}
```

### ✅ QUY TẮC 2: SỬ DỤNG GÓI `material_ui` CỦA DAILY YOU
* Thay vì chỉ import `package:flutter/material.dart`, hãy import:
  ```dart
  import 'package:material_ui/material_ui.dart';
  ```
* Gói này cung cấp chuẩn Material 3, Dynamic Color và tự động thích ứng với Dark Mode / Light Mode mà người dùng cài đặt trong Daily You.

### ✅ QUY TẮC 3: HỆ BẢNG MÀU ỨNG DỤNG & MÀU NGỮ NGHĨA (SEMANTIC COGNITIVE COLORS)
1. **Bảng màu chủ đạo ứng dụng (Color Hunt Palette):**
   - Ứng dụng sử dụng bảng màu Pastel hiện đại, dịu mắt từ [Color Hunt #B1B2FF](https://colorhunt.co/palette/b1b2ffaac4ffd2daffeef1ff):
     - Primary / Accent Color: `#B1B2FF` (Tím nhạt pastel thanh lịch)
     - Secondary Container: `#AAC4FF` (Xanh pastel dịu mát)
     - Surface Container: `#D2DAFF` (Tím lavender nhạt cho thẻ/card nền)
     - Scaffold Background: `#EEF1FF` (Trắng ánh tím kem dịu mắt, chống mỏi mắt)
   - Bảng màu này được thiết lập làm mặc định trong `ConfigProvider` và `ThemeModeProvider`.

2. **Quy tắc BẮT BUỘC về màu nhận diện trực quan (Semantic Colors):**
   > [!IMPORTANT]
   > Màu chủ đạo pastel chỉ áp dụng cho khung viền, nền và thanh công cụ. Đối với các biểu tượng trạng thái học tập và chỉ số nhận thức, **BẮT BUỘC tuân thủ đúng màu ngữ nghĩa tiêu chuẩn**, tuyệt đối không biến thành màu pastel:
   - 🔥 **Ngọn lửa Streak (Chuỗi ngày học):** Bắt buộc dùng màu **Cam lửa rực rỡ** (`#EA580C` đến `#F97316`). Không đổi thành màu tím/hồng pastel vì làm mất bản chất nhận diện "ngọn lửa bùng cháy".
   - ❌ **Lỗi phát âm / Đọc sai:** Bắt buộc dùng màu **Đỏ** (`#D32F2F`).
   - ✅ **Phát âm đúng / Đạt chuẩn / Trôi chảy:** Bắt buộc dùng màu **Xanh lá cây** (`#2E7D32`).
   - ⚠️ **Cảnh báo / Cần cải thiện:** Dùng màu **Vàng cam / Hổ phách** (`#F57C00`).
   - ⭐ **Câu tự tạo của học viên (Custom):** Badge màu **Hổ phách** (`Colors.amber.shade900` trên nền `Colors.amber.shade100`).

---

## 3. Màn hình Mẫu chuẩn cho TV4 & TV5 (Tính năng Học Thực Tế & Tự Tạo Câu)

Nhóm đã dựng sẵn màn hình mẫu hoàn chỉnh:
👉 [`lib/pages/practice_speech_page.dart`](file:///C:/Users/HP/Desktop/Daily_You_TH3_learningenglish/lib/pages/practice_speech_page.dart)

### Điểm nổi bật nâng cấp:
1. **Kho câu luyện tập thực tế theo chủ đề (24 câu mẫu mặc định):**
   - 💬 **Giao tiếp hằng ngày (Daily Conversation):** Lời chào, hỏi thăm, thói quen hằng ngày.
   - ✈️ **Du lịch & Di chuyển (Travel & Transport):** Hỏi đường, làm thủ tục khách sạn, gọi xe.
   - 💼 **Môi trường Công sở (Work & Office):** Thuyết trình, họp dự án, trao đổi email.
   - ☕ **Ẩm thực & Nhà hàng (Dining & Food):** Đặt bàn, gọi món, thanh toán.
2. **Tính năng Tự tạo câu luyện tập / Flashcard của riêng học viên:**
   - Nút **"+ Thêm câu mới"** mở hộp thoại [`AddSentenceDialog`](file:///C:/Users/HP/Desktop/Daily_You_TH3_learningenglish/lib/widgets/add_sentence_dialog.dart).
   - Cho phép học viên nhập: Câu tiếng Anh muốn luyện, Ý nghĩa tiếng Việt, Phiên âm IPA (tùy chọn) và chọn Chủ đề.
   - Dữ liệu lưu an toàn vào bảng `study_sentences` trong SQLite và gắn chặt với `userId` của học viên đó.
   - Tab **"⭐ Câu của tôi"** lọc riêng danh sách câu tự tạo, hỗ trợ xóa câu không còn nhu cầu ôn tập.

Màn hình này đã được kết nối sẵn vào hệ thống menu chính của ứng dụng tại:
- Desktop/Tablet: Mục menu **"Luyện phát âm"** trên Sidebar bên trái.
- Mobile: Tab **"Phát âm"** trên NavigationBar bên dưới.
- Dashboard TV3: Nút **"Luyện tập ngay"** trên trang Tiến độ học tập tự động nhảy sang màn hình này.

---

## 4. Hướng dẫn dành riêng cho TV4 (Speech API & Microphone)

### Nhiệm vụ của TV4:
1. Quản lý việc xin quyền Micro từ thiết bị.
2. Xử lý logic Bật / Dừng thu âm tiếng Anh của học viên.
3. Lưu file âm thanh ghi âm vào thư mục bộ nhớ tạm của ứng dụng.
4. Gọi API Speech Recognition để chuyển giọng nói thành văn bản (`recognizedText`).

### Vị trí gắn code trong [`practice_speech_page.dart`](file:///C:/Users/HP/Desktop/Daily_You_TH3_learningenglish/lib/pages/practice_speech_page.dart):
Tìm đến các khu vực đã đánh dấu:
- Hàm `_startRecording()`: Khởi động bộ ghi âm mic và đếm giây.
- Hàm `_stopRecording()`: Dừng thu âm, lưu đường dẫn file vào `_recordedAudioPath` và gán kết quả nhận dạng vào `_recognizedText`.
- Nút Micro thu âm lớn ở Card **"Khu vực TV4: Thu âm & Nhận dạng giọng nói"**.

```dart
// [VÍ DỤ TV4 TÍCH HỢP]:
void _stopRecording() async {
  _recordingTimer?.cancel();
  setState(() => _isRecording = false);

  // 1. Dừng thu âm và lấy file âm thanh
  final audioPath = await AudioRecorderService.stop();

  // 2. Gọi Speech Recognition API
  final recognizedSpeech = await SpeechToTextService.recognize(audioPath);

  // 3. Cập nhật giao diện để TV5 nhận dữ liệu
  setState(() {
    _recordedAudioPath = audioPath;
    _recognizedText = recognizedSpeech;
  });
}
```

---

## 5. Hướng dẫn dành riêng cho TV5 (Chấm điểm phát âm & Lưu CSDL)

### Nhiệm vụ của TV5:
1. Tiếp nhận câu mẫu luyện tập (`targetSentence`) và văn bản/âm thanh do TV4 cung cấp (`_recognizedText` / `_recordedAudioPath`).
2. Thực hiện thuật toán so khớp âm hoặc gọi AI API chấm điểm phát âm:
   - Điểm tổng quan (0 - 100).
   - Điểm thành phần: Accuracy (Độ chuẩn xác), Fluency (Độ trôi chảy), Completeness (Độ hoàn thiện).
   - Danh sách điểm từng từ (`WordScore`): Từ nào đạt chuẩn (xanh), từ nào cần sửa (vàng/đỏ).
   - Danh sách lỗi phát âm (`MispronouncedWord`): Âm chuẩn vs Âm đọc sai.
   - Nhận xét và hướng dẫn chỉnh sửa (`aiFeedback`).
3. Lưu kết quả vào CSDL SQLite thông qua DAO của TV1.

### Vị trí gắn code trong [`practice_speech_page.dart`](file:///C:/Users/HP/Desktop/Daily_You_TH3_learningenglish/lib/pages/practice_speech_page.dart):
Tìm đến hàm:
- `_evaluatePronunciation()`: Gọi thuật toán/API chấm điểm và cập nhật đối tượng `_latestResult = PronunciationResult(...)`.
- `_saveResultToDatabase()`: Đã được viết sẵn hoàn chỉnh! Hàm này tự động lấy ID của học viên đang đăng nhập và lưu song song vào cả 2 bảng `PracticeHistoryDao` và `PronunciationResultDao`.

```dart
// [VÍ DỤ TV5 TÍCH HỢP]:
Future<void> _evaluatePronunciation() async {
  setState(() => _isScoring = true);

  final target = _sampleSentences[_selectedSentenceIndex]['sentence']!;
  
  // Gọi AI chấm điểm dựa trên audio của TV4 và câu mẫu
  final result = await PronunciationScoringService.evaluate(
    targetSentence: target,
    recognizedText: _recognizedText,
    audioFilePath: _recordedAudioPath,
  );

  setState(() {
    _isScoring = false;
    _latestResult = result;
  });
}
```

---

## 6. Cơ chế Đăng nhập & Đổi Tài khoản (Multi-User Session)

Để phục vụ kiểm thử nhiều học viên độc lập:
1. **Thanh thông tin học viên (`UserProfileBar`):**
   - Đã được gắn trên đỉnh của trang Tiến độ học tập và trang Luyện phát âm.
   - Luôn hiển thị tên học viên hiện tại và nút **"Đổi tài khoản"**.
2. **Hộp thoại đổi tài khoản (`UserSwitchDialog`):**
   - Mở ra khi bấm vào avatar hoặc nút Đổi tài khoản.
   - Cho phép chọn nhanh giữa các tài khoản học viên có sẵn trong máy.
   - Cho phép bấm **"+ Thêm tài khoản học viên mới"** để tạo người dùng mới ngay lập tức.
3. **Tính độc lập dữ liệu (Data Isolation):**
   - Khi chuyển sang Học viên B, toàn bộ tiến độ, streak ngọn lửa và lịch sử bài luyện của Học viên A sẽ ẩn đi và hiển thị riêng dữ liệu của Học viên B.

---

## 7. Checklist kiểm tra giao diện trước khi bàn giao

Trước khi tạo Pull Request, thành viên cần tự kiểm tra:
- [ ] Không có `Scaffold` / `AppBar` lồng bên trong trang con.
- [ ] Chạy `flutter test` thành công 100%.
- [ ] Không có cảnh báo lỗi cú pháp (`flutter analyze` không có warning nghiêm trọng).
- [ ] Thử chuyển tài khoản học viên xem dữ liệu có hiển thị đúng người đó hay không.


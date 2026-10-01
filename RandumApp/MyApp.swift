import SwiftUI

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}



/*
 nay tui học swift nữa, tui sẽ làm 1 application và trước hết là config project, welcome screen và module auth của application
 
 ý tưởng của tui như sau
 - 1 welcome-screen (dạng chào mừng user) có nút "get started" -> tạm thời sang screen sign up
 - 1 module UI auth layout gồm 3 màn hình (sign in, sign up, forgot-pw) như sau:
 1. UI sign in gồm 2 input (email và pw) + nút "go to sign up" để sang screen của sign up + nút "forgot password" để sang screen của forgot password + nút "sign in" -> click vào thì print ra dữ liệu của các input trong 1 object data
 2. UI sign up gồm 5 input (email, name, code, pw, confirm pw) + nút "go to sign in" để sang screen của sign in + nút "sign up" -> click vào thì print ra dữ liệu của các input trong 1 object data
 3. UI forgot pw gồm 4 input (email, code, pw, confirm pw) + nút "reset password" -> click vào thì print ra dữ liệu của các input trong 1 object data
 
 
 ***note
 - input pw và confirm pw: UI phải có con mắt -> user touch sẽ hide và see được trường dữ liệu
 - input code ở form sign up và forgot pw: trên input UI có 1 nút "send" ở bên phải của ô input -> bấm send thì sẽ đếm ngược 300 giây -> print ra object data {email: "", otpType: "forgot_password" | "sign_up"}
 
 *** thứ ông làm
 tui cần ông chỉ project structure như thế nào? tạo thư mục và file code ra sao cho chuẩn production? code các navigation screen ra sao
 sau đó ông chỉ cần giúp tôi code 2 screen là welcome screen, sign up screen và setup việc chuyển screen từ welcome screen sang sign up screen
 và tui sẽ tự học và code 2 screen còn lại
 
 UI làm na ná image tui gửi (màu sắc và UI)
 */

#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>

#include "resource.h"

namespace {

// Scale helper to convert logical scaler values to physical using passed in
// scale factor
int Scale(int source, double scale_factor) {
  return static_cast<int>(source * scale_factor);
}

// Dynamically loads the |GetScaleFactorForMonitor| from the Shcore.dll.
// This API is only available on Windows 8.1+.
typedef HRESULT (*GetScaleFactorForMonitorPtr)(HMONITOR, DEVICE_SCALE_FACTOR*);
double GetDpiScaleForMonitor(HMONITOR monitor) {
  static GetScaleFactorForMonitorPtr get_scale_factor_for_monitor_func =
      nullptr;
  if (get_scale_factor_for_monitor_func == nullptr) {
    HMODULE shcore = GetModuleHandleA("shcore");
    if (shcore) {
      get_scale_factor_for_monitor_func =
          reinterpret_cast<GetScaleFactorForMonitorPtr>(
              GetProcAddress(shcore, "GetScaleFactorForMonitor"));
    }
  }
  if (get_scale_factor_for_monitor_func != nullptr) {
    DEVICE_SCALE_FACTOR scale_factor;
    if (SUCCEEDED(get_scale_factor_for_monitor_func(monitor, &scale_factor))) {
      return static_cast<double>(scale_factor) / 100.0;
    }
  }
  return 1.0;
}

// Retrieves a class instance pointer for |window|
Win32Window* GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

// Scales a child HWND by |scale_factor|. Used for resizing the child HWND
// after the top level window is resized.
void ScaleChild(HWND child, double scale_factor) {
  DWORD child_style = GetWindowLong(child, GWL_STYLE);
  if (child_style & WS_VISIBLE) {
    RECT child_rect;
    GetClientRect(child, &child_rect);
    int new_width = Scale(child_rect.right, scale_factor);
    int new_height = Scale(child_rect.bottom, scale_factor);
    SetWindowPos(child, nullptr, 0, 0, new_width, new_height,
                 SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOMOVE);
  }
}

}  // namespace

Win32Window::Win32Window() {
  RegisterMessageHandlers();
}

Win32Window::~Win32Window() {
  if (window_handle_) {
    Destroy();
  }
}

bool Win32Window::CreateAndShow(const std::wstring& title, const Point& origin,
                                const Size& size, HWND parent) {
  Destroy();

  const wchar_t* window_class =
      L"FLUTTER_RUNNER_WIN32_WINDOW";

  WNDCLASS window_class_struct{};
  window_class_struct.lpszClassName = window_class;
  window_class_struct.cbClsExtra = 0;
  window_class_struct.cbWndExtra = 0;
  window_class_struct.hIcon = LoadIcon(nullptr, IDI_APPLICATION);
  window_class_struct.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class_struct.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
  window_class_struct.lpszMenuName = nullptr;
  window_class_struct.hInstance = GetModuleHandle(nullptr);
  window_class_struct.lpfnWndProc = WndProc;

  RegisterClass(&window_class_struct);

  POINT target_point = {static_cast<LONG>(origin.x),
                        static_cast<LONG>(origin.y)};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
  dpi_scale_ = GetDpiScaleForMonitor(monitor);

  window_handle_ = CreateWindow(
      window_class, title.c_str(),
      WS_OVERLAPPEDWINDOW | WS_VISIBLE,
      Scale(origin.x, dpi_scale_), Scale(origin.y, dpi_scale_),
      Scale(size.width, dpi_scale_), Scale(size.height, dpi_scale_),
      parent, nullptr, GetModuleHandle(nullptr), this);

  if (!window_handle_) {
    return false;
  }

  return OnCreate();
}

void Win32Window::Destroy() {
  OnDestroy();

  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame;
  GetClientRect(window_handle_, &frame);

  SetWindowPos(content, nullptr, frame.left, frame.top, frame.right,
               frame.bottom, SWP_NOZORDER | SWP_NOACTIVATE);
}

HWND Win32Window::GetHandle() {
  return window_handle_;
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

RECT Win32Window::GetClientArea() {
  RECT frame;
  GetClientRect(window_handle_, &frame);
  return frame;
}

LRESULT Win32Window::MessageHandler(HWND hwnd, UINT message, WPARAM wparam,
                                    LPARAM lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;

    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                   newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

      return 0;
    }
    case WM_SIZE:
      if (child_content_ != nullptr) {
        RECT child_rect;
        GetClientRect(window_handle_, &child_rect);
        // Size the child window to fill the client area.
        SetWindowPos(child_content_, nullptr, child_rect.left, child_rect.top,
                     child_rect.right, child_rect.bottom,
                     SWP_NOZORDER | SWP_NOACTIVATE);
      }
      return 0;

    case WM_ACTIVATE:
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      return 0;

    case WM_SETFOCUS:
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      return 0;
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

void Win32Window::RegisterMessageHandlers() {
  message_handlers_ = {
      {WM_DESTROY, [this](HWND hwnd, UINT message, WPARAM wparam,
                           LPARAM lparam) {
        return MessageHandler(hwnd, message, wparam, lparam);
      }},
      {WM_DPICHANGED, [this](HWND hwnd, UINT message, WPARAM wparam,
                             LPARAM lparam) {
        return MessageHandler(hwnd, message, wparam, lparam);
      }},
      {WM_SIZE, [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        return MessageHandler(hwnd, message, wparam, lparam);
      }},
      {WM_ACTIVATE, [this](HWND hwnd, UINT message, WPARAM wparam,
                           LPARAM lparam) {
        return MessageHandler(hwnd, message, wparam, lparam);
      }},
      {WM_SETFOCUS, [this](HWND hwnd, UINT message, WPARAM wparam,
                           LPARAM lparam) {
        return MessageHandler(hwnd, message, wparam, lparam);
      }},
  };
}

LRESULT Win32Window::WndProc(HWND const window, UINT const message,
                             WPARAM const wparam,
                             LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_ptr = reinterpret_cast<CREATESTRUCT*>(lparam)->lpCreateParams;
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_ptr));
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

bool Win32Window::OnCreate() {
  return true;
}

void Win32Window::OnDestroy() {
  if (child_content_) {
    child_content_ = nullptr;
  }
}

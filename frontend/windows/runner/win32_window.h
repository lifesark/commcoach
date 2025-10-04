#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// A class abstraction for a high DPI-aware Win32 Window. Intended for use with
// DirectManipulation.
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates and shows a win32 window with |title| that is positioned and sized
  // using |origin| and |size|. The window uses |child_content| as its content.
  // Returns true if the window was created successfully.
  bool CreateAndShow(const std::wstring& title, const Point& origin,
                     const Size& size, HWND parent = nullptr);

  // Destroys the window and its content.
  void Destroy();

  // Installs a function to be called when the window receives a WM_SIZE message
  // from the OS.
  void SetChildContent(HWND content);

  // Returns the backing Window handle to enable clients to set icon and other
  // window properties. Returns nullptr if the window has been destroyed.
  HWND GetHandle();

  // If true, closing this window will quit the application.
  void SetQuitOnClose(bool quit_on_close);

  // Return a RECT representing the bounds of the current client area.
  RECT GetClientArea();

 protected:
  // Processes and routes salient window messages for mouse handling,
  // size change and DPI. Delegates handling of these to member functions
  // that inheritors can override.
  virtual LRESULT MessageHandler(HWND window, UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept;

  // Called when CreateAndShow is called, allowing subclass window-related
  // setup. Subclasses should return false if setup fails.
  virtual bool OnCreate();

  // Called when Destroy is called.
  virtual void OnDestroy();

 private:
  using MessageHandlerRegistry = std::map<UINT, std::function<LRESULT(
      HWND, UINT, WPARAM, LPARAM)>>;

  void RegisterMessageHandlers();

  // OS callback called by message pump. Won't be called directly by clients.
  static LRESULT CALLBACK WndProc(HWND const window, UINT const message,
                                  WPARAM const wparam, LPARAM const lparam) noexcept;

  // Retrieves a class instance pointer for |window|
  static Win32Window* GetThisFromHandle(HWND const window) noexcept;

  bool quit_on_close_ = false;

  // window handle for top level window.
  HWND window_handle_ = nullptr;

  // window handle for hosted content.
  HWND child_content_ = nullptr;

  MessageHandlerRegistry message_handlers_;

  // The current DPI scale for the window
  double dpi_scale_ = 1.0;
};

#endif  // RUNNER_WIN32_WINDOW_H_

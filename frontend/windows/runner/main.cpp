#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <shellapi.h>
#include <winreg.h>
#include <string>

#include "flutter_window.h"
#include "utils.h"

// Function to register URL protocol handler
void RegisterURLProtocol()
{
  HKEY hKey;
  std::wstring protocolName = L"com.corigge.app";
  std::wstring exePath;
  wchar_t path[MAX_PATH];

  // Get the path to the current executable
  GetModuleFileName(NULL, path, MAX_PATH);
  exePath = path;

  // Create/Open the protocol key
  if (RegCreateKeyEx(HKEY_CURRENT_USER,
                     (L"Software\\Classes\\" + protocolName).c_str(),
                     0, NULL, REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS)
  {
    // Set default value to protocol name
    RegSetValueEx(hKey, NULL, 0, REG_SZ,
                  (BYTE *)L"URL:Corigge Protocol",
                  static_cast<DWORD>((wcslen(L"URL:Corigge Protocol") + 1) * sizeof(wchar_t)));

    // Add URL Protocol marker
    RegSetValueEx(hKey, L"URL Protocol", 0, REG_SZ,
                  (BYTE *)L"", static_cast<DWORD>(sizeof(wchar_t)));

    // Create command key
    HKEY hKeyCommand;
    if (RegCreateKeyEx(hKey,
                       L"shell\\open\\command",
                       0, NULL, REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hKeyCommand, NULL) == ERROR_SUCCESS)
    {
      // Set command to execute
      std::wstring command = L"\"" + exePath + L"\" \"%1\"";
      RegSetValueEx(hKeyCommand, NULL, 0, REG_SZ,
                    (BYTE *)command.c_str(),
                    static_cast<DWORD>((command.length() + 1) * sizeof(wchar_t)));
      RegCloseKey(hKeyCommand);
    }
    RegCloseKey(hKey);
  }
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command)
{
  // Register URL protocol handler
  RegisterURLProtocol();

  // Handle incoming URL if launched with arguments
  int argc;
  LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
  if (argc > 1)
  {
    // The URL will be in argv[1]
    // You can process it here or pass it to Flutter
  }
  LocalFree(argv);

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent())
  {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"corigge", origin, size))
  {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0))
  {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

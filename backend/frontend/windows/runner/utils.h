#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// Creates a new console for the process, and redirects stdout and stderr
// to it for both the runner and the Flutter library.
void CreateAndAttachConsole();

// Takes a null-terminated wchar_t* encoded in UTF-16 and returns a std::string
// encoded in UTF-8. An invalid input sequence is replaced with the Unicode
// replacement character. No null character is inserted into the output
// string.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// Gets the command line arguments passed in as a std::vector<std::string>,
// encoded in UTF-8. Returns an empty vector if the command line could not
// be read for any reason.
std::vector<std::string> GetCommandLineArguments();

#endif  // RUNNER_UTILS_H_

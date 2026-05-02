//cd C:\dev\nim-0.19.0\dist\mingw64\bin
//g++ -static-libstdc++ -static-libgcc C:\dev\nim-work-win64\getClipBoardData\getClipBoardData.cpp -o C:\dev\nim-work-win64\getClipBoardData\getClip.exe

//https://docs.microsoft.com/ja-jp/windows/desktop/dataxchg/clipboard

//http://wisdom.sakura.ne.jp/system/winapi/win32/win90.html

#include <windows.h>
#include <iostream>

//best way to return an std::string that local to a function
//https://stackoverflow.com/questions/3976935/best-way-to-return-an-stdstring-that-local-to-a-function

int main(int argc, char *argv[]){

    HGLOBAL   hglb; 
    LPTSTR    lptstr; 
    LPVOID lpvoid;
    HWND hwnd;

    //std::cout << "getClip.exe started" << std::endl;

    if (!IsClipboardFormatAvailable(CF_TEXT)) {
        std::cout << "Error(1): Can't find ClipboardFormatAvailable" << std::endl;
        return 1;
    }
        
    if (!OpenClipboard(NULL)){
        std::cout << "Error(2): Can't OpenClipboard" << std::endl;
        return 2;
    } 

    hglb = GetClipboardData(CF_TEXT); 
    if (hglb != NULL) { 
        lptstr = (LPTSTR)GlobalLock(hglb);
        if (lptstr != NULL) 
        { 
            // Call the application-defined ReplaceSelection 
            // function to insert the text and repaint the 
            // window. 

            //std::cout << "clipboard is " << lptstr << std::endl;
            std::cout << lptstr << std::endl;

            GlobalUnlock(hglb); 
        } 
    } else {
        std::cout << "HGLOBAL is null." << std::endl;    
    }
    CloseClipboard(); 

    //std::cout << "getClip.exe ended" << std::endl;

    return 0; 
}
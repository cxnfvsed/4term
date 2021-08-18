#include <windows.h>
#include <iostream>

using namespace std;
void ReadCOM();
//объявляем обработчики соm портов
HANDLE hserial;
HANDLE hserial1;

int main(int argc, char* argv[])
{
    //объявляем строки с именами портов
    LPCTSTR sPortname = L"COM2";
    LPCTSTR sPortname1 = L"COM1";
    hserial = ::CreateFile(sPortname, GENERIC_READ | GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);//открываем для записи и чтения
    hserial1 = ::CreateFile(sPortname1, GENERIC_READ | GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if (hserial == INVALID_HANDLE_VALUE)//проверяем работоспособность com1
    {
        if (GetLastError() == ERROR_FILE_NOT_FOUND)
        {
            cout << "serial port doesnt existd.\n";
        }
        cout << "some other error occured.\n";
    }
    if (hserial1 == INVALID_HANDLE_VALUE)//проверяем работоспособность com1
    {
        if (GetLastError() == ERROR_FILE_NOT_FOUND)
        {
            cout << "serial port doesnt existd.\n";
        }
        cout << "some other error occured.\n";
    }
    //настраиваем праметры соединения
    DCB dcbSerialParams = { 0 };
    dcbSerialParams.DCBlength = sizeof(dcbSerialParams);
    if (!GetCommState(hserial, &dcbSerialParams))
    {
        cout << "getting state error.\n";
    }
    dcbSerialParams.BaudRate = CBR_9600;//скорость передачи
    dcbSerialParams.ByteSize = 8;//длина передаваемого байта
    dcbSerialParams.StopBits = ONESTOPBIT;//1 стоп бит
    dcbSerialParams.Parity = NOPARITY;//отсутствие бита четности
    if (!SetCommState(hserial, &dcbSerialParams))
    {
        cout << "error setting serial port state.\n";
    }


    //аналогичная настройка 2 порта
    DCB dcbSerialParams1 = { 0 };
    dcbSerialParams1.DCBlength = sizeof(dcbSerialParams1);
    if (!GetCommState(hserial, &dcbSerialParams1))
    {
        cout << "getting state error.\n";
    }
    dcbSerialParams1.BaudRate = CBR_9600;//скорость передачи
    dcbSerialParams1.ByteSize = 8;//длина передаваемого байта
    dcbSerialParams1.StopBits = ONESTOPBIT;//1 стоп бит
    dcbSerialParams1.Parity = NOPARITY;//отсутствие бита четности
    if (!SetCommState(hserial1, &dcbSerialParams1))
    {
        cout << "error setting serial port state.\n";
    }

    char data[] = "Hello";//строка для передачи
    DWORD dwSize = sizeof(data);//размер строки
    DWORD dwByteWritten;//количество переданных байт

    //посылаем строку
    BOOL iRet = WriteFile(hserial, data, dwSize, &dwByteWritten, NULL);
    //вывод кол-ва отосланных байт
    cout << dwSize << "Bytes in string." << dwByteWritten << "Bytes sended." << endl;


    //цикл чтения данных
    while (true)
    {
        ReadCOM();
    }
    return 0;
}


void ReadCOM()//функция чтения
{
    DWORD iSize;
    char sReceiveChar;
    while (true)
    {
        ReadFile(hserial, &sReceiveChar, 1, &iSize, 0);//получаем 1 байт
        if (iSize > 0)//если что-то принято,то выводим
        {
            cout << sReceiveChar;
        }
    }
}
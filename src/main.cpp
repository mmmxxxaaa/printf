extern "C" void MyPrintf(const char* format, ...);

int main()
{
    MyPrintf("check call from C %c, %o\n", 'k', 101);
    return 0;
}

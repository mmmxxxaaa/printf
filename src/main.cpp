extern "C" void MyPrintf(const char* format, ...);

int main()
{
    MyPrintf("check call from C %c, %o, %s\n", 'k', 101, "Vova Naumov bigbob");
    return 0;
}

extern "C" void MyPrintf(const char* format, ...);

int main()
{
    MyPrintf("check call from C %c, %d\n", 'k', 101);
    return 0;
}

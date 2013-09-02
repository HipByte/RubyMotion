// Convert UTF-8 from Normalization Form C (NFC) to Normalization Form D (NFD)
// This tool outputs the escaped Ruby string.
//   ex) ./nfd "a" #=> "\x61"
#import <Foundation/Foundation.h>

int main(int argc, char* argv[])
{
    [[NSAutoreleasePool alloc] init];
    if (argc <= 0) {
	exit(0);
    }

    const char *cstr = argv[1];
    NSString *str = [[[NSString alloc] initWithCString:cstr encoding:NSUTF8StringEncoding] autorelease];
    NSString *str_nfd = [str decomposedStringWithCanonicalMapping];

    // output the string
    const char *string = [str_nfd UTF8String];
    const long len = strlen(string);
    printf("\"");
    for (int i = 0; i < len; i++) {
	printf("\\x%X", (unsigned char)string[i]);
    }
    printf("\"");
}

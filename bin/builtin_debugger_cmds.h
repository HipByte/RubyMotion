
#define cmd_pro ""\
    "if $argc != 1\n"\
	"help print-ruby-object\n"\
    "else\n"\
	"po rb_inspect($arg0)\n"\
    "end\n"

#define cmd_pri ""\
    "if $argc == 1\n"\
	"po rb_inspect((void *)rb_ivar_get(self, (void *)rb_intern($arg0)))\n" \
    "else\n"\
	"if $argc == 2\n"\
	    "po rb_inspect((void *)rb_ivar_get($arg0, (void *)rb_intern($arg1)))\n" \
	"else\n"\
	    "help print-ruby-ivar\n"\
	"end\n"\
    "end\n"

#define BUILTIN_DEBUGGER_CMDS ""\
    "define print-ruby-object\n" cmd_pro "end\n"\
    "define pro\n" cmd_pro "end\n"\
    "document print-ruby-object\n"\
        "print-ruby-object(obj): inspects the given 'obj'\n"\
    "end\n"\
    "define print-ruby-ivar\n" cmd_pri "end\n"\
    "define pri\n" cmd_pri "end\n"\
    "document print-ruby-ivar\n"\
        "print-ruby-ivar(name): inspects the given instance variable 'name' on self\n"\
        "print-ruby-ivar(rcv, name): inspects the given instance variable 'name' on 'rcv'\n"\
    "end\n"

#!/usr/bin/python

import lldb

def pro(debugger, command, result, internal_dict):
    """
    pro(obj): inspects the given 'obj'
    """
    args = command.split()
    if len(args) != 1:
        print pro.__doc__
        return

    cmd = "po rb_inspect(" + args[0] + ")"
    lldb.debugger.HandleCommand(cmd)


def pri(debugger, command, result, internal_dict):
    """
    pri(name): inspects the given instance variable 'name' on self
    pri(rcv, name): inspects the given instance variable 'name' on 'rcv'
    """
    args = command.split()
    if len(args) == 1:
        cmd = "po rb_inspect((void *)rb_ivar_get(self, (void *)rb_intern(" + args[0] + ")))"
    elif len(args) == 2:
        cmd = "po rb_inspect((void *)rb_ivar_get(" + args[0] + ", (void *)rb_intern(" + args[1] + ")))"
    else:
        print pri.__doc__
        return

    lldb.debugger.HandleCommand(cmd)


# And the initialization code to add your commands
def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand('command script add -f lldb.pro print-ruby-object')
    debugger.HandleCommand('command script add -f lldb.pro pro')
    debugger.HandleCommand('command script add -f lldb.pri print-ruby-ivar')
    debugger.HandleCommand('command script add -f lldb.pri pri')


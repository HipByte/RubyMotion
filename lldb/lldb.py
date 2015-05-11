#!/usr/bin/python
# Copyright (c) 2013, HipByte SPRL and contributors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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


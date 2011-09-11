############################################################################
# Eggdrop Puppet notificator
# -----------------------
#   Date: 2011-08-29
#   Version: v0.1
#   Author(s): Alexander Fortin <alexander.fortin@gmail.com>
#   Website: http://www.devsum.it/
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
############################################################################

#### PUT HERE YOUR CUSTOM CONFIGS ####
set channel "#devsum"
set delayinminutes "60"
set pollingfrequency "5"
set puppetreports "/var/lib/puppet/reports"
set sendemail "false"
set emailaddress "root"
######### STOP EDITING HERE ##########

set scriptversion "0.2"

if {![info exists myproc_running]} {
    timer $pollingfrequency puppetcheck
    set myproc_running 1
}

proc dosendemail { line } {
    global emailaddress delayinminutes
    exec echo "Huston, have we got a problem?!" | mail -s "\[Eggdrop\] Puppet node $line last seen > $delayinminutes min ago" $emailaddress
}

proc puppetcheck {} {
    global channel delayinminutes puppetreports sendemail pollingfrequency
    set tempfilefind "/tmp/eggdropfind"
    set tempfilels "/tmp/eggdropls"
    set tempfilediff "/tmp/eggdropdiff"

    set tempfile [ open $tempfilefind w ]
    exec find $puppetreports -type d -mmin -$delayinminutes | cut -d "/" -f 6 | sort >@ $tempfile
    close $tempfile
    set tempfile [ open $tempfilels w ]
    exec ls -1 $puppetreports >@ $tempfile
    close $tempfile
    set tempfile [ open $tempfilediff w ]
    exec diff -c $tempfilefind $tempfilels | grep ^\+ | cut -c "3-" >@ $tempfile &
    close $tempfile
    after 500

    set tempfile [ open $tempfilediff ]
    set lineNumber 0
    while {[gets $tempfile line] >= 0} {
        puthelp "PRIVMSG $channel :\[\002PuppetDashboard\002\] $line node last seen > $delayinminutes min ago"
        putloglev p $channel "<PuppetDashboard> $line node last seen > $delayinminutes min ago"
        if {$sendemail != "false"} { dosendemail $line }
    }
    close $tempfile

    exec rm $tempfilefind
    exec rm $tempfilels
    exec rm $tempfilediff

    timer $pollingfrequency puppetcheck
    return 1
}

putlog "puppet.tcl v$scriptversion https://github.com/shaftoe/eggdrop-puppet-notificator - Loaded."

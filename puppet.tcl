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

#### PUT HERE YOUR CUSTOM CONFIGS ####
set channel "#devsum"
set delayinminutes "60"
set pollingfrequency "2"
set puppetreports "/var/lib/puppet/reports"
######### STOP EDITING HERE ##########

set scriptversion "0.1"

proc puppetcheck {} {
    global channel delayinminutes puppetreports
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
    exec diff -n $tempfilefind $tempfilels | egrep ".+\..+\..+" >@ $tempfile
    close $tempfile
    after 500

    set tempfile [ open $tempfilediff ]
    set lineNumber 0
    while {[gets $tempfile line] >= 0} {
        puthelp "PRIVMSG $channel :\[\002PuppetDashboard\002\] $line node last seen > $delayinminutes min ago"
        putloglev p $channel "PuppetDashboard - $line node last seen > $delayinminutes min ago"
    }
    close $tempfile

    exec rm $tempfilefind
    exec rm $tempfilels
    exec rm $tempfilediff
}

timer $pollingfrequency puppetcheck
putlog "puppet-check v$scriptversion loaded"

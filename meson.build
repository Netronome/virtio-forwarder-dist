#   BSD LICENSE
#
#   Copyright(c) 2016-2020 Netronome.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions
#   are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#     * Neither the name of Netronome nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if get_option('srpm')
    prep_run_rpmbuild = find_program(join_paths('scripts', 'prep_and_run_rpmbuild.sh'))
    if get_option('outdir') == 'outdir'
        error('Please provide destination for RPM via the "-Doutdir" option')
    else
        outdir = get_option('outdir')
    endif

    # Only generate a source-rpm and print stdout of rpmbuild script
    r = run_command(prep_run_rpmbuild, '-f', 'bs', '-o', outdir)
    message(r.stdout().strip())
endif

if get_option('rpm')
    prep_run_rpmbuild = find_program(join_paths('scripts', 'prep_and_run_rpmbuild.sh'))
    if get_option('outdir') == 'outdir'
        error('Please provide destination for RPM via the "-Doutdir" option')
    else
        outdir = get_option('outdir')
    endif

    if get_option('static')
        run_target('build_rpm', command: [prep_run_rpmbuild, '-s', '-o', outdir])
    else
        run_target('build_rpm', command: [prep_run_rpmbuild, '-o', outdir])
    endif
endif

if get_option('deb')
    prep_run_debuild = find_program(join_paths('scripts', 'prep_and_run_debuild.sh'))

    if get_option('static')
        run_target('build_deb', command: [prep_run_debuild, '-s'])
    else
        run_target('build_deb', command: [prep_run_debuild])
    endif
endif

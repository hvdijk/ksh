########################################################################
#                                                                      #
#               This software is part of the ast package               #
#          Copyright (c) 1982-2012 AT&T Intellectual Property          #
#          Copyright (c) 2020-2022 Contributors to ksh 93u+m           #
#                      and is licensed under the                       #
#                 Eclipse Public License, Version 2.0                  #
#                                                                      #
#                A copy of the License is available at                 #
#      https://www.eclipse.org/org/documents/epl-2.0/EPL-2.0.html      #
#         (with md5 checksum 84283fa8859daf213bdda5a9f8d1be1d)         #
#                                                                      #
#                  David Korn <dgk@research.att.com>                   #
#                  Martijn Dekker <martijn@inlv.org>                   #
#                                                                      #
########################################################################

. "${SHTESTS_COMMON:-${0%/*}/_common}"

function test_glob
{
	typeset lineno expected drop arg got sep op val add del
	lineno=$1
	shift
	if	[[ $1 == --* ]]
	then	del=${1#--}
		shift
	fi
	if	[[ $1 == ++* ]]
	then	add=${1#++}
		shift
	fi
	expected=$1
	shift
	if	(( contrary ))
	then	if	[[ $expected == "<Beware> "* ]]
		then	expected=${expected#"<Beware> "}
			expected="$expected <Beware>"
		fi
		if	[[ $expected == *"<aXb> <abd>"* ]]
		then	expected=${expected/"<aXb> <abd>"/"<abd> <aXb>"}
		fi
	fi
	for arg
	do	got="$got$sep<$arg>"
		sep=" "
	done
	if	(( ignorant && aware ))
	then	if	[[ $del ]]
		then	got="<$del> $got"
		fi
		if	[[ $add ]]
		then	expected="<$add> $expected"
		fi
	fi
	if	[[ $got != "$expected" ]]
	then	'err_exit' $lineno "glob${ [[ -o globstar ]] && print star; } -- expected '$expected', got '$got'"
	fi
}
alias test_glob='test_glob $LINENO'

function test_case
{
	typeset lineno expected subject pattern got
	lineno=$1 expected=$2 subject=$3 pattern=$4
	eval "
		case $subject in
		$pattern)	got='<match>' ;;
		*)		got='<nomatch>' ;;
		esac
	"
	if	[[ $got != "$expected" ]]
	then	'err_exit' $lineno "case $subject in $pattern) -- expected '$expected', got '$got'"
	fi
}
alias test_case='test_case $LINENO'

unset undefined

export LC_COLLATE=C
touch B b
set -- *
case $* in
'b B')	contrary=1 ;;
b|B)	ignorant=1 ;;
esac
set -- $(LC_ALL=C sh -c 'echo [a-c]')
case $* in
B)	aware=1 ;;
esac
rm -rf *

touch a b c d abc abd abe bb bcd ca cb dd de Beware
mkdir bdir

test_glob '<a> <abc> <abd> <abe> <X*>' a* X*
test_glob '<a> <abc> <abd> <abe>' \a*

if	( set --nullglob ) 2>/dev/null
then
	set --nullglob

	test_glob '<a> <abc> <abd> <abe>' a* X*

	set --nonullglob
fi

if	( set --failglob ) 2>/dev/null
then
	set --failglob
	mkdir tmp
	touch tmp/l1 tmp/l2 tmp/l3

	test_glob '' tmp/l[12] tmp/*4 tmp/*3
	test_glob '' tmp/l[12] tmp/*4 tmp/*3

	rm -r tmp
	set --nofailglob
fi

test_glob '<bdir/>' b*/
test_glob '<*>' \*
test_glob '<a*>' 'a*'
test_glob '<a*>' a\*
test_glob '<c> <ca> <cb> <a*> <*q*>' c* a\* *q*
test_glob '<**>' "*"*
test_glob '<**>' \**
test_glob '<\.\./*/>' "\.\./*/"
test_glob '<s/\..*//>' 's/\..*//'
test_glob '</^root:/{s/^[!:]*:[!:]*:\([!:]*\).*$/\1/>' "/^root:/{s/^[!:]*:[!:]*:\([!:]*\).*"'$'"/\1/"
test_glob '<abc> <abd> <abe> <bb> <cb>' [a-c]b*
test_glob ++Beware '<abd> <abe> <bb> <bcd> <bdir> <ca> <cb> <dd> <de>' [a-y]*[!c]
test_glob '<abd> <abe>' a*[!c]

touch a-b aXb

test_glob '<a-b> <aXb>' a[X-]b

touch .x .y

test_glob --Beware '<Beware> <d> <dd> <de>' [!a-c]*

if	mkdir a\*b 2>/dev/null
then
	touch a\*b/ooo

	test_glob '<a*b/ooo>' a\*b/*
	test_glob '<a*b/ooo>' a\*?/*
	test_case '<match>' '!7' '*\!*'
	test_case '<match>' 'r.*' '*.\*'
	test_glob '<abc>' a[b]c
	test_glob '<abc>' a["b"]c
	test_glob '<abc>' a[\b]c
	test_glob '<abc>' a?c
	test_case '<match>' 'abc' 'a"b"c'
	test_case '<match>' 'abc' 'a*c'
	test_case '<nomatch>' 'abc' '"a?c"'
	test_case '<nomatch>' 'abc' 'a\*c'
	test_case '<nomatch>' 'abc' 'a\[b]c'
	test_case '<match>' '"$undefined"' '""'
	test_case '<match>' 'abc' 'a["\b"]c'

	rm -rf mkdir a\*b
fi

mkdir man
mkdir man/man1
touch man/man1/sh.1

test_glob '<man/man1/sh.1>' */man*/sh.*
test_glob '<man/man1/sh.1>' $(echo */man*/sh.*)
test_glob '<man/man1/sh.1>' "$(echo */man*/sh.*)"

test_case '<match>' 'abc' 'a***c'
test_case '<match>' 'abc' 'a*****?c'
test_case '<match>' 'abc' '?*****??'
test_case '<match>' 'abc' '*****??'
test_case '<match>' 'abc' '*****??c'
test_case '<match>' 'abc' '?*****?c'
test_case '<match>' 'abc' '?***?****c'
test_case '<match>' 'abc' '?***?****?'
test_case '<match>' 'abc' '?***?****'
test_case '<match>' 'abc' '*******c'
test_case '<match>' 'abc' '*******?'
test_case '<match>' 'abcdecdhjk' 'a*cd**?**??k'
test_case '<match>' 'abcdecdhjk' 'a**?**cd**?**??k'
test_case '<match>' 'abcdecdhjk' 'a**?**cd**?**??k***'
test_case '<match>' 'abcdecdhjk' 'a**?**cd**?**??***k'
test_case '<match>' 'abcdecdhjk' 'a**?**cd**?**??***k**'
test_case '<match>' 'abcdecdhjk' 'a****c**?**??*****'
test_case '<match>' "'-'" '[-abc]'
test_case '<match>' "'-'" '[abc-]'
test_case '<match>' "'\\'" '\\'
test_case '<match>' "'\\'" '[\\]'
test_case '<match>' "'\\'" "'\\'"
test_case '<match>' "'['" '[[]'
test_case '<match>' '[' '[[]'
test_case '<match>' "'['" '['
test_case '<match>' '[' '['
test_case '<match>' "'[abc'" "'['*"
test_case '<nomatch>' "'[abc'" '[*'
test_case '<match>' '[abc' "'['*"
test_case '<nomatch>' '[abc' '[*'
test_case '<match>' 'abd' "a[b/c]d"
test_case '<match>' 'a/d' "a[b/c]d"
test_case '<match>' 'acd' "a[b/c]d"
test_case '<match>' "']'" '[]]'
test_case '<match>' "'-'" '[]-]'
test_case '<match>' 'p' '[a-\z]'
test_case '<match>' '"/tmp"' '[/\\]*'
test_case '<nomatch>' 'abc' '??**********?****?'
test_case '<nomatch>' 'abc' '??**********?****c'
test_case '<nomatch>' 'abc' '?************c****?****'
test_case '<nomatch>' 'abc' '*c*?**'
test_case '<nomatch>' 'abc' 'a*****c*?**'
test_case '<nomatch>' 'abc' 'a********???*******'
test_case '<nomatch>' "'a'" '[]'
test_case '<nomatch>' 'a' '[]'
test_case '<nomatch>' "'['" '[abc'
test_case '<nomatch>' '[' '[abc'

test_glob ++Beware '<b> <bb> <bcd> <bdir>' b*
test_glob '<Beware> <b> <bb> <bcd> <bdir>' [bB]*

if	( set --nocaseglob ) 2>/dev/null
then
	set --nocaseglob

	test_glob '<Beware> <b> <bb> <bcd> <bdir>' b*
	test_glob '<Beware> <b> <bb> <bcd> <bdir>' [b]*
	test_glob '<Beware> <b> <bb> <bcd> <bdir>' [bB]*

	set --nonocaseglob
fi

if	( set -f ) 2>/dev/null
then
	set -f

	test_glob '<*>' *

	set +f
fi

if	( set --noglob ) 2>/dev/null
then
	set --noglob

	test_glob '<*>' *

	set --glob
fi

FIGNORE='@(.*|*)'
test_glob '<*>' *

FIGNORE='@(.*|*c|*e|?)'
test_glob '<a-b> <aXb> <abd> <bb> <bcd> <bdir> <ca> <cb> <dd> <man>' *

FIGNORE='@(.*|*b|*d|?)'
test_glob '<Beware> <abc> <abe> <bdir> <ca> <de> <man>' *

FIGNORE=
test_glob '<man/man1/sh.1>' */man*/sh.*
test_glob '<.x> <.y> <Beware> <a> <a-b> <aXb> <abc> <abd> <abe> <b> <bb> <bcd> <bdir> <c> <ca> <cb> <d> <dd> <de> <man>' *
test_glob '<.x> <.y>' .*

FIGNORE='@(*[abcd]*)'
test_glob '<.x> <.y>' *
test_glob '<.x> <.y>' .*

unset FIGNORE
test_glob '<bb> <ca> <cb> <dd> <de>' ??
test_glob '<man/man1/sh.1>' */man*/sh.*
test_glob '<Beware> <a> <a-b> <aXb> <abc> <abd> <abe> <b> <bb> <bcd> <bdir> <c> <ca> <cb> <d> <dd> <de> <man>' *
test_glob '<.x> <.y>' .*

GLOBIGNORE='.*:*'
set -- *
if	[[ $1 == '*' ]]
then
	GLOBIGNORE='.*:*c:*e:?'
	test_glob '<>' *

	GLOBIGNORE='.*:*b:*d:?'
	test_glob '<>' *

	unset GLOBIGNORE
	test_glob '<>' *
	test_glob '<man/man1/sh.1>' */man*/sh.*

	GLOBIGNORE=
	test_glob '<man/man1/sh.1>' */man*/sh.*
fi
unset GLOBIGNORE

function test_sub
{
	x='${subject'$2'}'
	eval g=$x
	if	[[ "$g" != "$3" ]]
	then	'err_exit' $1 subject="'$subject' $x failed, expected '$3', got '$g'"
	fi
}
alias test_sub='test_sub $LINENO'

set --noglob
((SHOPT_BRACEPAT)) && set --nobraceexpand

subject='A regular expressions test'

test_sub '/e/#'               'A r#gular expressions test'
test_sub '//e/#'              'A r#gular #xpr#ssions t#st'
test_sub '/[^e]/#'            '# regular expressions test'
test_sub '//[^e]/#'           '###e######e###e########e##'
test_sub '/+(e)/#'            'A r#gular expressions test'
test_sub '//+(e)/#'           'A r#gular #xpr#ssions t#st'
test_sub '/@-(e)/#'           'A r#gular expressions test'
test_sub '//@-(e)/#'          'A r#gular #xpr#ssions t#st'
test_sub '/?(e)/#'            '#A regular expressions test'
test_sub '//?(e)/#'           '#A# #r#g#u#l#a#r# #x#p#r#s#s#i#o#n#s# #t#s#t#'
test_sub '/*(e)/#'            '#A regular expressions test'
test_sub '//*(e)/#'           '#A# #r#g#u#l#a#r# #x#p#r#s#s#i#o#n#s# #t#s#t#'
test_sub '//@(e)/[\1]'        'A r[e]gular [e]xpr[e]ssions t[e]st'
test_sub '//@-(e)/[\1]'       'A r[e]gular [e]xpr[e]ssions t[e]st'
test_sub '//+(e)/[\1]'        'A r[e]gular [e]xpr[e]ssions t[e]st'
test_sub '//+-(e)/[\1]'       'A r[e]gular [e]xpr[e]ssions t[e]st'
test_sub '//@(+(e))/[\1]'     'A r[e]gular [e]xpr[e]ssions t[e]st'
test_sub '//@(+-(e))/[\1]'    'A r[e]gular [e]xpr[e]ssions t[e]st'
test_sub '//-(e)/#'           'A regular expressions test'
test_sub '//--(e)/#'          'A regular expressions test'
test_sub '//?(e)/[\1]'        '[]A[] []r[e]g[]u[]l[]a[]r[] [e]x[]p[]r[e]s[]s[]i[]o[]n[]s[] []t[e]s[]t[]'
test_sub '//{0,1}(e)/[\1]'    '[]A[] []r[e]g[]u[]l[]a[]r[] [e]x[]p[]r[e]s[]s[]i[]o[]n[]s[] []t[e]s[]t[]'
test_sub '//*(e)/[\1]'        '[]A[] []r[e]g[]u[]l[]a[]r[] [e]x[]p[]r[e]s[]s[]i[]o[]n[]s[] []t[e]s[]t[]'
test_sub '//{0,}(e)/[\1]'     '[]A[] []r[e]g[]u[]l[]a[]r[] [e]x[]p[]r[e]s[]s[]i[]o[]n[]s[] []t[e]s[]t[]'
test_sub '//@(?(e))/[\1]'     '[]A[] []r[e]g[]u[]l[]a[]r[] [e]x[]p[]r[e]s[]s[]i[]o[]n[]s[] []t[e]s[]t[]'
test_sub '//@({0,1}(e))/[\1]' '[]A[] []r[e]g[]u[]l[]a[]r[] [e]x[]p[]r[e]s[]s[]i[]o[]n[]s[] []t[e]s[]t[]'
test_sub '//@(*(e))/[\1]'     '[]A[] []r[e]g[]u[]l[]a[]r[] [e]x[]p[]r[e]s[]s[]i[]o[]n[]s[] []t[e]s[]t[]'
test_sub '//@({0,}(e))/[\1]'  '[]A[] []r[e]g[]u[]l[]a[]r[] [e]x[]p[]r[e]s[]s[]i[]o[]n[]s[] []t[e]s[]t[]'
test_sub '/?-(e)/#'           '#A regular expressions test'
test_sub '/@(?-(e))/[\1]'     '[]A regular expressions test'
test_sub '/!(e)/#'            '#'
test_sub '//!(e)/#'           '#'
test_sub '/@(!(e))/[\1]'      '[A regular expressions test]'
test_sub '//@(!(e))/[\1]'     '[A regular expressions test]'

subject='e'

test_sub '/!(e)/#'            '#e'
test_sub '//!(e)/#'           '#e#'
test_sub '/!(e)/[\1]'         '[]e'
test_sub '//!(e)/[\1]'        '[]e[]'
test_sub '/@(!(e))/[\1]'      '[]e'
test_sub '//@(!(e))/[\1]'     '[]e[]'

subject='a'

test_sub '/@(!(a))/[\1]'      '[]a'
test_sub '//@(!(a))/[\1]'     '[]a[]'

subject='aha'

test_sub '/@(!(a))/[\1]'      '[aha]'
test_sub '//@(!(a))/[\1]'     '[aha]'
test_sub '/@(!(aha))/[\1]'    '[ah]a'
test_sub '//@(!(aha))/[\1]'   '[ah][a]'

# ======
# Recursive double-star globbing (globstar) tests
set --glob --globstar
mkdir -p d_un/d_duo/d_tres/d_quatro d_un/d_duo/d_3/d_4
touch d_un/d_duo/.tres
ln -s d_duo d_un/d_sym

# As of commit 5312a59d, globstar failed to expand **/. or **/.. or **/./file or **/../file
# https://github.com/ksh93/ksh/issues/146#issuecomment-790845391
test_glob \
 '<d_un/.> <d_un/d_duo/.> <d_un/d_duo/d_3/.> <d_un/d_duo/d_3/d_4/.> <d_un/d_duo/d_tres/.> <d_un/d_duo/d_tres/d_quatro/.>' \
  d_un/**/.
test_glob \
 '<d_un/..> <d_un/d_duo/..> <d_un/d_duo/d_3/..> <d_un/d_duo/d_3/d_4/..> <d_un/d_duo/d_tres/..> <d_un/d_duo/d_tres/d_quatro/..>' \
  d_un/**/..
test_glob \
 '<d_un/./d_duo> <d_un/./d_sym> <d_un/d_duo/./d_3> <d_un/d_duo/./d_tres> <d_un/d_duo/d_3/./d_4> <d_un/d_duo/d_tres/./d_quatro>' \
  d_un/**/./d_*
test_glob \
 '<d_un/../d_un> <d_un/d_duo/../d_duo> <d_un/d_duo/../d_sym> <d_un/d_duo/d_3/../d_3> <d_un/d_duo/d_3/../d_tres>'\
' <d_un/d_duo/d_3/d_4/../d_4> <d_un/d_duo/d_tres/../d_3> <d_un/d_duo/d_tres/../d_tres> <d_un/d_duo/d_tres/d_quatro/../d_quatro>' \
  d_un/**/../d_*
test_glob '<d_un/d_duo/.tres>' d_un/**/.*
test_glob '<d_un/d_duo/d_3/../.tres> <d_un/d_duo/d_tres/../.tres>' d_un/*/**/../.*
test_glob \
	'<d_un/d_duo/d_3/../.tres> <d_un/d_duo/d_tres/../.tres> <d_un/d_sym/d_3/../.tres> <d_un/d_sym/d_tres/../.tres>' \
	d_un/**/*/../.*
test_glob '<d_un/./d_duo/./d_3/./.././.tres> <d_un/./d_duo/./d_tres/./.././.tres>' d_un/./**/./*/./.././.*

# New in 93u+m 2021-03-06: follow symlink to directory if specified literally or matched by a regular glob pattern component
# https://github.com/ksh93/ksh/issues/146#issuecomment-792142794
test_glob '<d_un/d_sym/d_3> <d_un/d_sym/d_3/d_4> <d_un/d_sym/d_tres> <d_un/d_sym/d_tres/d_quatro>' d_un/d_sym/**
test_glob '<d_un/d_sym> <d_un/d_sym/d_3> <d_un/d_sym/d_3/d_4> <d_un/d_sym/d_tres> <d_un/d_sym/d_tres/d_quatro>' d_un/d_sy[m]/**
test_glob '<d_un/d_sym/d_3/d_4>' d_un/d_sym/d_3/**
test_glob '<d_un/d_sym/d_3/d_4>' d_un/d_sy[m]/d_3/**
test_glob '<d_un/d_duo> <d_un/d_duo/d_3> <d_un/d_duo/d_3/d_4> <d_un/d_duo/d_tres> <d_un/d_duo/d_tres/d_quatro>' **/d_duo/**
test_glob '<d_un/d_sym> <d_un/d_sym/d_3> <d_un/d_sym/d_3/d_4> <d_un/d_sym/d_tres> <d_un/d_sym/d_tres/d_quatro>' **/d_sym/**
test_glob '<d_un/d_sym> <d_un/d_sym/d_3> <d_un/d_sym/d_3/d_4> <d_un/d_sym/d_tres> <d_un/d_sym/d_tres/d_quatro>' **/d_s[y]m/**
test_glob '<d_un/d_sym> <d_un/d_sym/d_3> <d_un/d_sym/d_3/d_4> <d_un/d_sym/d_tres> <d_un/d_sym/d_tres/d_quatro>' **/d_*ym/**
test_glob '<d_un/d_sym//d_3> <d_un/d_sym//d_3/d_4> <d_un/d_sym//d_tres> <d_un/d_sym//d_tres/d_quatro>' **/d_sym//**
test_glob '<d_un/d_sym//d_3> <d_un/d_sym//d_3/d_4> <d_un/d_sym//d_tres> <d_un/d_sym//d_tres/d_quatro>' **/d_[s]ym//**
test_glob '<d_un/d_sym//d_3> <d_un/d_sym//d_3/d_4> <d_un/d_sym//d_tres> <d_un/d_sym//d_tres/d_quatro>' **/d_*ym//**

set --noglobstar

# ======
# Shell quoting within bracket expressions in glob patterns had no effect
# https://github.com/ksh93/ksh/issues/488

mkdir BUG_BRACQUOT
cd BUG_BRACQUOT
: > b
test_glob '<[a-c]>' [a'-'c]
test_glob '<[!N]>' ['!'N]
test_glob '<[^N]>' ['^'N]
test_glob '<[a-c]>' [a$'-'c]
test_glob '<[!N]>' [$'!'N]
test_glob '<[^N]>' [$'^'N]
test_glob '<[a-c]>' [a"-"c]
test_glob '<[!N]>' ["!"N]
test_glob '<[^N]>' ["^"N]
test_glob '<[a-c]>' [a\-c]
test_glob '<[!N]>' [\!N]
test_glob '<[^N]>' [\^N]
# quoting should also work for the end character ']'
test_glob '<[]-z]>' [\]\-z]
test_glob '<[]-z]>' [']-z']
test_glob '<[]-z]>' ["]-z"]
cd ..

# ======
exit $((Errors<125?Errors:125))

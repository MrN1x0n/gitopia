#!/bin/bash
TMP_DIR="/tmp/tmpinstalldir"
function cleanup {
	echo rm -rf $TMP_DIR > /dev/null
}
function fail {
	cleanup
	msg=$1
	echo "============"
	printf "Error: $msg" 1>&2
	exit 1
}
function install {
	#settings
	USER="gitopia"
	PROG="git-remote-gitopia"
	PROG2="git-gitopia"
	MOVE="true"
	VERSION="1.3.0"
	INSECURE="false"
	OUT_DIR="/usr/local/bin"
	OBJECTS_URL="https://server.gitopia.com"
	#bash check
	[ ! "$BASH_VERSION" ] && fail "Please use bash instead"
	[ ! -d $OUT_DIR ] && fail "output directory missing: $OUT_DIR"
	#dependency check, assume we are a standard POISX machine
	which find > /dev/null || fail "find not installed"
	which xargs > /dev/null || fail "xargs not installed"
	which sort > /dev/null || fail "sort not installed"
	which tail > /dev/null || fail "tail not installed"
	which cut > /dev/null || fail "cut not installed"
	which du > /dev/null || fail "du not installed"
	GET=""
	if which curl > /dev/null; then
		GET="curl"
		if [[ $INSECURE = "true" ]]; then GET="$GET --insecure"; fi
		GET="$GET --fail -# -L"
	elif which wget > /dev/null; then
		GET="wget"
		if [[ $INSECURE = "true" ]]; then GET="$GET --no-check-certificate"; fi
		GET="$GET -qO-"
	else
		fail "neither wget/curl are installed"
	fi
	#find OS #TODO BSDs and other posixs
	case `uname -s` in
	Darwin) OS="darwin";;
	Linux) OS="linux";;
	*) fail "unknown os: $(uname -s)";;
	esac
	#find ARCH
	if uname -m | grep amd64 > /dev/null; then
		ARCH="amd64"
	elif uname -m | grep x86_64 > /dev/null; then
		ARCH="amd64"
	elif uname -m | grep arm64 > /dev/null; then
		ARCH="arm64"
	elif uname -m | grep arm > /dev/null; then
		ARCH="arm" #TODO armv6/v7
	elif uname -m | grep 386 > /dev/null; then
		ARCH="386"
	else
		fail "unknown arch: $(uname -m)"
	fi
	#choose from asset list
	URL=""
	FTYPE=""
	case "${OS}_${ARCH}" in
	"darwin_amd64")
		URL="${OBJECTS_URL}/releases/${USER}/git-remote-gitopia/v${VERSION}/git-remote-gitopia_${VERSION}_darwin_amd64.tar.gz"
		FTYPE=".tar.gz"
		;;
	"darwin_arm64")
		URL="${OBJECTS_URL}/releases/${USER}/git-remote-gitopia/v${VERSION}/git-remote-gitopia_${VERSION}_darwin_arm64.tar.gz"
		FTYPE=".tar.gz"
		;;
	"linux_amd64")
		URL="${OBJECTS_URL}/releases/${USER}/git-remote-gitopia/v${VERSION}/git-remote-gitopia_${VERSION}_linux_amd64.tar.gz"
		FTYPE=".tar.gz"
		;;
	"linux_386")
		URL="${OBJECTS_URL}/releases/${USER}/git-remote-gitopia/v${VERSION}/git-remote-gitopia_${VERSION}_linux_386.tar.gz"
		FTYPE=".tar.gz"
		;;
    "linux_arm")
		URL="${OBJECTS_URL}/releases/${USER}/git-remote-gitopia/v${VERSION}/git-remote-gitopia_${VERSION}_linux_arm.tar.gz"
		FTYPE=".tar.gz"
		;;
    "linux_arm64")
		URL="${OBJECTS_URL}/releases/${USER}/git-remote-gitopia/v${VERSION}/git-remote-gitopia_${VERSION}_linux_arm64.tar.gz"
		FTYPE=".tar.gz"
		;;
	*) fail "No asset for platform ${OS}-${ARCH}";;
	esac
	#got URL! download it...
	echo -n "Installing ${USER}/${PROG} v${VERSION}"
	
	echo "....."
	
	#enter tempdir
	sudo mkdir -p $TMP_DIR
	cd $TMP_DIR
	if [[ $FTYPE = ".gz" ]]; then
		which gzip > /dev/null || fail "gzip is not installed"
		#gzipped binary
		NAME="${PROG}_${RELEASE}_${OS}_${ARCH}.gz"
		GZURL="${OBJECTS_URL}/releases/${USER}/git-remote-gitopia/v${VERSION}/${NAME}"
		#gz download!
		bash -c "$GET $URL" | gzip -d - > $PROG || fail "download failed"
	elif [[ $FTYPE = ".tar.gz" ]] || [[ $FTYPE = ".tgz" ]]; then
		#check if archiver progs installed
		which tar > /dev/null || fail "tar is not installed"
		which gzip > /dev/null || fail "gzip is not installed"
		bash -c "$GET $URL" | tar zxf - || fail "download failed"
	elif [[ $FTYPE = ".zip" ]]; then
		which unzip > /dev/null || fail "unzip is not installed"
		bash -c "$GET $URL" > tmp.zip || fail "download failed"
		unzip -o -qq tmp.zip || fail "unzip failed"
		rm tmp.zip || fail "cleanup failed"
	elif [[ $FTYPE = "" ]]; then
		bash -c "$GET $URL" > "starport_${OS}_${ARCH}" || fail "download failed"
	else
		fail "unknown file type: $FTYPE"
	fi
	#check binaries exist
	if [[ ! -f "$PROG" || ! -f "$PROG2" ]]; then
		fail "could not find binaries"
	fi
	#move into PATH or cwd
	(sudo chmod +x $PROG $PROG2) || fail "chmod +x failed"
	
	(sudo mv $PROG $PROG2 $OUT_DIR) || fail "mv failed\nRun the below command to finish the installation\n\nsudo mv ${TMP_DIR}/${PROG} ${TMP_DIR}/${PROG2} ${OUT_DIR}\n\n" #FINAL STEP!
	echo "Installed $PROG at $OUT_DIR/$PROG"
	echo "Installed $PROG2 at $OUT_DIR/$PROG2"
	#done
	cleanup
}
install

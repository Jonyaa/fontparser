#! /bin/bash


### Bash font parser and installer for mac OS
### Written by Jonathan Yaari Barzilay


# Default Constants
FORCE_DOWNLOAD=0
DEST_PATH="/Users/`whoami`/Desktop/fonts/"
REPLY=
PATTERN="https:\/\/[/A-Z\.a-z0-9\-]*\.woff2"
PATTERN2="\/[a-zA-Z\/\-]*\.woff2"
SLEEP_TIMEOUT=1
VERBOSE_DOWNLOAD=0

FONT_FILE=${@: -1}

function check()
{
	while (( $#  )); do
		case $1 in
			-f|--file)
				shift
				FONT_FILE=$1
				;;
			-y)
				FORCE_DOWNLOAD=1
				;;
			-d|--dest)
				shift
				DEST_PATH=$1
				;;
            -v|--verbose)
                VERBOSE_DOWNLOAD=1
                ;;
            --help)
                usage
                ;;
			-*)
				usage
			   	exit 1	
				;;
		esac
		shift
	done
}


function usage()
{
	echo -e "Usage: fontparser <website url | file path>
        
        -y                  } Download all font found without asking
        -d | --dest PATH    } Directory path to download the font files to (default $DEST_PATH)
        -v | --verbose      } Show file download progress
        --help              } Show this message and exit"
    exit 0
}


function grep_http_urls()
{
    STYLESHEET_URLS=$(curl -s $FONT_FILE | grep link | grep -o "href=\'[^\']*'" | grep -o "http[^'\"]*")
    STYLESHEET_URLS+=" $FONT_FILE"
    echo STYLESHEET URLS: $STYLESHEET_URLS

    for url in $STYLESHEET_URLS; do
        FONT_URLS+=$(curl -s $url | grep -o $PATTERN)
        FONT_URLS+=' '
    done
    if [[ ! "$FONT_URLS" =~ 'http' ]]; then
        DOMAIN_NAME=$(echo $FONT_FILE | grep -o 'https://[^\/]*')
        DOMAIN_NAME=$(echo $DOMAIN_NAME | sed 's/\//\\\//g')
        for url in $STYLESHEET_URLS; do
            FONT_URLS+=$(curl -s $url | grep -o $PATTERN2 | sed "s/^/$DOMAIN_NAME/g")
            FONT_URLS+=' '
        done
    fi
}


function grep_urls()
{
    if [[ $FONT_FILE =~ ^http.* ]]; then
        grep_http_urls
    else
        FONT_URLS=$(grep -o $PATTERN $FONT_FILE)
    fi

    if [ -z "$FONT_URLS" ]; then
        echo "No fonts found."
        exit 1
    fi
}


function download_fonts()
{
    downloaded_files=
    if [ "$VERBOSE_DOWNLOAD" = "1" ]; then
		for url in $@; do
			fn=$(echo $url | rev | cut -d / -f 1 | rev)
			curl  $url > $DEST_PATH/$fn
            downloaded_files+="\n  ⦿  $DEST_PATH$fn"
            fonttools ttLib.woff2 decompress -q  -o $DEST_PATH$(echo $fn | sed 's/woff2/ttf/') $DEST_PATH$fn && rm -f $DEST_PATH$fn
		done
    else
       for url in $@; do
			fn=$(echo $url | rev | cut -d / -f 1 | rev)
			curl  -s --progress-bar $url > $DEST_PATH/$fn
            downloaded_files+="\n  ⦿  $DEST_PATH$(echo $fn | sed 's/woff2/ttf/')"
            fonttools ttLib.woff2 decompress -q  -o $DEST_PATH$(echo $fn | sed 's/woff2/ttf/') $DEST_PATH$fn && rm -f $DEST_PATH$fn
		done
    fi
    echo -e "\nDownloaded: $downloaded_files"
}


function download_prompt()
{
    FONT_URLS=$(echo $FONT_URLS | tr ' ' '\n' | sort | uniq)
    echo "Found these urls:"
    url_counter=0
	for url in $FONT_URLS; do
        echo -e "  $url_counter)\t$url"
        url_counter=$((url_counter+1))
	done

	while [ "$REPLY" != "y" ] && [ "$REPLY" != "n" ] && [ "$REPLY" != "r" ]; do
		read -p "Download to $DEST_PATH? (y|r|n) "
	done
		
	if [ "$REPLY" = "y" ]; then
		download_fonts $FONT_URLS
    elif [ "$REPLY" = "r" ]; then
        read -p "URL contains regex: "
        for url in $FONT_URLS; do
            TMP_FONT_URLS+="$(echo $url | grep $REPLY) "
        done
        url_counter=0
        echo "Matching fonts: "
        for url in $TMP_FONT_URLS; do
            echo -e "  $url_counter)\t$url"
        done
        read -p "Download? (y/n) "
        if [ "$REPLY" = y ]; then
            download_fonts $TMP_FONT_URLS
        else
            echo -e "\n    Thanks\n"
        fi
	else
		echo -e "\n    Thanks\n"
	fi
}


function main()
{
    if [ -z $1 ]; then
        usage
    fi
	check $@
	mkdir -p $DEST_PATH # Create destination folder if it does not exists
	grep_urls
	
	if [ "$FORCE_DOWNLOAD" = 0 ]; then
        download_prompt
	else
		download_fonts $FONT_URLS
	fi
}


main $@

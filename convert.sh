#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib

file_name=""
cover_file="embeded_cover.jpg"
extension="mp3"
convert=false
backup=false
erase=false
album=""
artist=""
track_album=""
chapter_list_file=""
chapter_name=""
ms=0
ss=0
ns=0
cn=0 #chapter number

while getopts ":a:p:r:t:c:f:o:l:bhe" optname
do
    case "$optname" in
        "h")
            echo "Usage:"
            echo ""
            echo "-a album name      : force album name"
            echo "-r artist name     : force artist name"
            echo "-t track album     : force track album name"
            echo "-f cover file      : force cover file instead of embeded"
            echo "-o output file name: set output file name instead of default"
            echo "-b                 : backup chapters file"
            echo "-c files extension : convert files with extension to m4a"
            echo "-l chapters list   : use external chapters list file"
            echo "-p chapter name    :"
            echo "-e                 : erase source audio files"
            exit 0;
            ;;
        "p")
            echo "Option $optname has value $OPTARG"
            chapter_name="$OPTARG"
            ;;
        "l")
            echo "Option $optname has value $OPTARG"
            if [ -f $OPTARG ]; then
                echo "File $OPTARG exists."
                chapter_list_file=$OPTARG
            fi
            ;;
        "a")
            echo "Option $optname has value $OPTARG"
            album="$OPTARG"
            ;;
        "r")
            echo "Option $optname has value $OPTARG"
            artist=$OPTARG
            ;;
        "t")
            echo "Option $optname has value $OPTARG"
            track_album=$OPTARG
            ;;
        "f")
            echo "Option $optname has value $OPTARG"
            echo "COVER FILE CHECK"
            if [ -f $OPTARG ]; then
                echo "File $OPTARG exists."
                cover_file=$OPTARG
            fi
            ;;
        "o")
            echo "Output file name will be: $OPTARG"
            file_name="$OPTARG"
            ;;
        "e")
            echo "Erase all source audio files"
            read -p "Are you sure? " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]];then
                erase=true
            fi
            ;;
        "b")
            echo "Leave backup files"
            backup=true
            ;;
        "c")
            echo "Convert files *.$OPTARG"
            convert=true
            extension=$OPTARG
            ;;
        "?")
            echo "Unknown option $OPTARG"
            exit 1
            ;;
        ":")
            echo "No argument value for option $OPTARG"
            exit 2
            ;;
        *)
            # Should not occur
            echo "Unknown error while processing options"
            exit 3
            ;;
    esac
done

if [ $convert == true ]; then
    echo "CONVERT ALL $extension to m4a"
    echo "It replace all existing m4a files!"
    read -p "Are you sure? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]];then
        for a in *.$extension; do
            f="${a[@]/%$extension/m4a}"
            avconv -y -i "$a" embeded_cover.jpg 2>&1 > /dev/null
            avconv -y -i "$a" -c:a libfdk_aac -vbr 1 -profile:a aac_he -ar 32k -vn -cutoff 16k "$f" 2>&1 > /dev/null
        done
    fi
fi

for i in *.m4a; do
    ((cn++))
    time=`MP4Box -info "$i" 2>&1 | grep -m2 Duration | tr -d [:alpha:],' ' | cut -f4 -d -`
    if [ $cn == 1 ]; then
        if [ -z "$artist" ]; then
            artist=`mp4info "$i" | grep Artist | cut -d ":" -f2 | cut -b 2-`
        fi
        if [ -z "$album" ]; then
            album=`mp4info "$i" | grep Album -m1| cut -d ":" -f2 | cut -b 2-`
        fi
        if [ -z "$track_album" ]; then
            track_album=`mp4info "$i" | grep Track: | cut -d ":" -f2 | cut -d 'f' -f2 | tr -d ' '`
        fi
    fi

    name=`mp4info "$i" | grep Name | cut -d ":" -f2 | cut -b 2-`
    track_num=`mp4info "$i" | grep Track: | cut -d ":" -f2 | cut -d 'o' -f1 | tr -d ' '`

    h=`echo $time | cut -d ':' -f 1`
    m=`echo $time | cut -d ':' -f 2`
    sn=`echo $time | cut -d ':' -f 3`
    s=`echo $time | cut -d ':' -f 3 | cut -d '.' -f1`
    n=`echo $time | cut -d ':' -f 3 | cut -d '.' -f2`

    echo CHAPTER$cn=`echo 0$hs | tail -c3`:`echo 0$ms | tail -c3`:`echo 0$ss | tail -c3`.`echo 00$ns | tail -c4` >> /dev/shm/chapter_info
    if [ -z "$chapter_name" ]; then
        echo CHAPTER"$cn"NAME=`echo 0$track_num | tail -c3`. "$artist" - "$name" >> /dev/shm/chapter_info
    else
        echo CHAPTER"$cn"NAME="$chapter_name"" "$cn  >> /dev/shm/chapter_info
    fi

    hs=`echo $(( 10#$hs + 10#$h))`
    ms=`echo $(( 10#$ms + 10#$m))`
    ss=`echo $(( 10#$ss + 10#$s))`
    ns=`echo $(( 10#$ns + 10#$n))`

    #ns
    if [ $ns -gt 999 ];then
        # echo too much ns
        ns=`echo $(( 10#$ns - 1000 ))`
        ss=`echo $(( 10#$ss + 1 ))`
    fi

    #s
    if [ $ss -gt 59 ];then
        # echo too much sek
        ss=`echo $(( 10#$ss - 60 ))`
        ms=`echo $(( 10#$ms + 1 ))`
    fi

    #m
    if [ $ms -gt 59 ];then
        # echo too much min
        ms=`echo $(( 10#$ms - 60 ))`
        hs=`echo $(( 10#$hs + 1 ))`
    fi

    echo Adding $i as a chapter.
    MP4Box -cat "$i" -tmp /dev/shm /dev/shm/album_tmp.mp4 2>&1 > /dev/null
    if [ $erase == true ];then
        echo "Erase $i"
        rm "$i"
    fi
done

if [ -z "$track_album" ]; then
    if [ $track_album == $cn ]; then
        echo "Album complete"
        echo "Added $cn tracks of $track_album in album."
    else
        echo "Warning! Chapters number is $cn while there is $track_album tracks on album."
    fi
else
    echo "Album complete"
fi

if [ -n "$chapter_list_file" ]; then 
    echo "Using external chapers file"
    cp -f "$chapter_list_file" /dev/shm/chapter_info
fi

echo "Adding chapters informations."
MP4Box -tmp /dev/shm -add /dev/shm/album_tmp.mp4 -chap /dev/shm/chapter_info /dev/shm/album_chap.mp4 2>&1 > /dev/null

if [ $backup == true ]; then
    echo "Move backup files"
    cp /dev/shm/chapter_info ./chapters.list
else
    echo "Do not backup files"
fi

rm /dev/shm/album_tmp.mp4 /dev/shm/chapter_info

mp4chaps --convert --chapter-qt /dev/shm/album_chap.mp4 > /dev/null

echo "Adding album informations."
mp4tags -album "$album" -artist "$artist" -song "$album (complete album)" -albumartist "$artist" /dev/shm/album_chap.mp4 > /dev/null

echo "Adding cover"
mp4art --add "$cover_file" /dev/shm/album_chap.mp4 > /dev/null

if [ -z "$file_name" ]; then
    file_name="$artist - $album.m4b"
fi

echo Renaming to "$file_name".
mv /dev/shm/album_chap.mp4 "./$file_name"

if [ $erase == true ];then
    echo "Erase source audio files"
    rm *.$extension
fi

echo " "
echo Duration: `echo 0$hs | tail -c3`:`echo 0$ms | tail -c3`:`echo 0$ss | tail -c3`.`echo 00$ns | tail -c4`
echo Chapters: $cn
echo " "
echo Enjoy!

exit 0


#!/bin/sh

if [ $# -eq 2 ] # good arguments 
then
   echo "Using " $1 " as repository for API stuff " $2 " as the spec destination"
   SPECHOME=$2
   REPOS=$1
else
   echo "This script requires 2 arguments: The location of the repository and the destination directory for the spec (both full paths). The first argument should point to a folder with three folders: static (where static html files are stored), widl (where WebIDL sources are stored) and resources (where additional resources such as wildproc, dtd, xsl... are stored). If the operation completes successfully the spec will be generated at the apis folder created on the specified destination folder."
   exit
fi

# This is the list of elements to be included in the spec, needs to be properly configured,
# additionally the XMLSOURCES element should include all the xml generated by the widls in
# order to include cross-references

# API Files that do not come from widls (edited manually) 
#STATICFILES='geolocation.html webinos-apis.js webinos-apis.css'
STATICFILES=$(ls "$REPOS/static/")

# Device API widls
#WIDLFILES='foo.widl'
WIDLFILES=$(ls $REPOS/widl/) 

# For widlproc processing
XSL=widlprocxmltohtml.xsl
XMLSOURCES=widlprocxmlsources.xml
DTD=widlprocxml.dtd

#get the right tools for unix of windows cygnus
$(widlproc 2> /dev/null)
[ $? != 127 ] && WIDLPROC=widlproc || WIDLPROC=$REPOS/resources/linux/widlproc 
[ -n "$OS" ] && [ "$OS" = "Windows_NT" ] && WIDLPROC=$REPOS/resources/win32/widlproc.exe

$(ls /opt/bitnami/common/lib/libxslt.so > /dev/null 2>&1)
[ $? = 0 ] && XSLTLIB=/opt/bitnami/common/lib
XSLPROC=xsltproc 
[ -n "$OS" ] && [ "$OS" = "Windows_NT" ] && XSLPROC=$REPOS/resources/win32/xsltproc.exe



#[ $? != 127 ] && WIDLPROC=widlproc.exe || WIDLPROC=$REPOS/resources/win32/widlproc.exe

# TODO: Here we should include an update to check the latest repository version is available
# Clean Directories used for the generation of the specs
rm -rf "$SPECHOME/apis"
mkdir "$SPECHOME/apis"

# Copy static content
for i in $STATICFILES
do
  cp "$REPOS/static/$i" "$SPECHOME/apis/"
done

# Generating dynamic content

# those files are required to be in the destination folder for HTML generation
cp "$REPOS/resources/$DTD" "$SPECHOME/apis/"
cp "$REPOS/resources/$XMLSOURCES" "$SPECHOME/apis/"
cp "$REPOS/resources/$XSL" "$SPECHOME/apis/"

# must be done in two steps in order to build the cross-references
for i in $WIDLFILES
do
	cp "$REPOS/widl/$i" "$SPECHOME/apis/"
	"$WIDLPROC" "$SPECHOME/apis/$i" > "$SPECHOME/apis/$(basename "$i" .widl).widlprocxml" 2>/dev/null
done

for i in $WIDLFILES
do
	LD_LIBRARY_PATH="${XSLTLIB}" "$XSLPROC" "$SPECHOME/apis/$XSL" "$SPECHOME/apis/${i}procxml" > "$SPECHOME/apis/$(basename "$i" .widl).html"
done

rm "$SPECHOME"/apis/*.widlprocxml
rm "$SPECHOME"/apis/*.widl
rm "$SPECHOME/apis/$DTD"
rm "$SPECHOME/apis/$XSL"
rm "$SPECHOME/apis/$XMLSOURCES"

# TODO: Here we should include an automatic commit to the repository of the spec

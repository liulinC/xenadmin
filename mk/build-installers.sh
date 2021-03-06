#!/bin/bash

# Copyright (c) Citrix Systems Inc. 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, 
# with or without modification, are permitted provided 
# that the following conditions are met: 
# 
# *   Redistributions of source code must retain the above 
#     copyright notice, this list of conditions and the 
#     following disclaimer. 
# *   Redistributions in binary form must reproduce the above 
#     copyright notice, this list of conditions and the 
#     following disclaimer in the documentation and/or other 
#     materials provided with the distribution. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND 
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
# SUCH DAMAGE.

set -eu

#sign applications
for file in XenCenterMain.exe CommandLib.dll MSTSCLib.dll XenCenterLib.dll XenCenterVNC.dll XenModel.dll XenOvf.dll XenOvfTransport.dll
do
  cd ${REPO}/XenAdmin/bin/Release && ${REPO}/sign.bat ${file}
done

cd ${REPO}/XenAdmin/bin/Release && ${REPO}/sign.bat ${BRANDING_BRAND_CONSOLE}.exe

cd ${REPO}/xe/bin/Release         && ${REPO}/sign.bat xe.exe
cd ${REPO}/xva_verify/bin/Release && ${REPO}/sign.bat xva_verify.exe

for file in Microsoft.ReportViewer.Common.dll Microsoft.ReportViewer.ProcessingObjectModel.dll Microsoft.ReportViewer.WinForms.dll
do
  cd ${REPO}/XenAdmin/ReportViewer && ${REPO}/sign.bat ${file}
done

for file in VNCControl.dll XenCenterLib.dll XenCenterVNC.dll XenServer.dll
do
  cd ${REPO}/VNCControl/bin/Release && ${REPO}/sign.bat ${file}
done 

cd ${REPO}/XenAdmin/bin/Release && ${REPO}/sign.bat CookComputing.XmlRpcV2.dll "XML-RPC.NET by Charles Cook, signed by ${BRANDING_COMPANY_NAME_SHORT}"
cd ${REPO}/XenAdmin/bin/Release && ${REPO}/sign.bat log4net.dll  "Log4Net by The Apache Software Foundation, signed by ${BRANDING_COMPANY_NAME_SHORT}"
cd ${REPO}/XenAdmin/bin/Release && ${REPO}/sign.bat ICSharpCode.SharpZipLib.dll "SharpZipLib by IC#Code, signed by ${BRANDING_COMPANY_NAME_SHORT}"
cd ${REPO}/XenAdmin/bin/Release && ${REPO}/sign.bat DiscUtils.dll "DiscUtils by Kenneth Bell, signed by ${BRANDING_COMPANY_NAME_SHORT}"
cd ${REPO}/XenAdmin/bin/Release && ${REPO}/sign.bat Ionic.Zip.dll "OSS, signed by ${BRANDING_COMPANY_NAME_SHORT}"
cd ${REPO}/XenAdmin/bin/Release && ${REPO}/sign.bat putty.exe "PuTTY by Simon Tatham, signed by ${BRANDING_COMPANY_NAME_SHORT}"

#create installers
compile_installer()
{
  if [ "$2" = "ja-jp" ]
  then
    langid=1041
    name=$1.$2
  elif [ "$2" = "zh-cn" ]
  then
    langid=2052
    name=$1.$2
  else
    langid=1033
    name=$1
  fi
   
  cd ${WIX}
  mkdir -p obj${name}
  Branding=${BRANDING_BRAND_CONSOLE} WixLangId=${langid} ${CANDLE} -ext WiXNetFxExtension -out obj${name}/ $1.wxs
   
  mkdir -p out${name}
  
  if [ "${name}" = "VNCControl" ]
  then
   ${LIGHT} -nologo obj${name}/$1.wixobj lib/WixUI_InstallDir.wixlib -loc wixlib/wixui_$2.wxl -ext WiXNetFxExtension -out out${name}/${name}.msi
  else
   ${LIGHT} -nologo obj${name}/$1.wixobj lib/WixUI_InstallDir.wixlib -loc wixlib/wixui_$2.wxl -loc $2.wxl -ext WiXNetFxExtension -out out${name}/${name}.msi
  fi
}

sign_msi()
{
  cd ${WIX}/out$1 && chmod a+rw $1.msi && ${REPO}/sign.bat $1.msi
}

#create just english msi
if [ "XenCenter" != "${BRANDING_BRAND_CONSOLE}" ]
then 
  cd ${WIX}
  mv XenCenter.wxs ${BRANDING_BRAND_CONSOLE}.wxs
  mv XenCenter.l10n.wxs ${BRANDING_BRAND_CONSOLE}.l10n.wxs
fi

compile_installer "${BRANDING_BRAND_CONSOLE}" "en-us" && sign_msi "${BRANDING_BRAND_CONSOLE}"

#then create l10n msi containing all resources
compile_installer "${BRANDING_BRAND_CONSOLE}.l10n" "en-us" && sign_msi "${BRANDING_BRAND_CONSOLE}.l10n"
compile_installer "${BRANDING_BRAND_CONSOLE}.l10n" "ja-jp" && sign_msi "${BRANDING_BRAND_CONSOLE}.l10n.ja-jp"
compile_installer "${BRANDING_BRAND_CONSOLE}.l10n" "zh-cn" && sign_msi "${BRANDING_BRAND_CONSOLE}.l10n.zh-cn"

cp ${WIX}/out${BRANDING_BRAND_CONSOLE}.l10n/${BRANDING_BRAND_CONSOLE}.l10n.msi \
   ${WIX}/out${BRANDING_BRAND_CONSOLE}.l10n.ja-jp/${BRANDING_BRAND_CONSOLE}.l10n.ja-jp.msi \
   ${WIX}/out${BRANDING_BRAND_CONSOLE}.l10n.zh-cn/${BRANDING_BRAND_CONSOLE}.l10n.zh-cn.msi \
   ${WIX}
 
cd ${WIX} && cp ${BRANDING_BRAND_CONSOLE}.l10n.msi ${BRANDING_BRAND_CONSOLE}.l10n.zh-tw.msi
cd ${WIX} && cscript /nologo CodePageChange.vbs ZH-TW ${BRANDING_BRAND_CONSOLE}.l10n.zh-tw.msi

#create localised mst files and then embed them into l10n msi
cd ${WIX} && wscript msidiff.js ${BRANDING_BRAND_CONSOLE}.l10n.msi ${BRANDING_BRAND_CONSOLE}.l10n.ja-jp.msi ja-jp.mst
cd ${WIX} && wscript msidiff.js ${BRANDING_BRAND_CONSOLE}.l10n.msi ${BRANDING_BRAND_CONSOLE}.l10n.zh-cn.msi zh-cn.mst
cd ${WIX} && wscript msidiff.js ${BRANDING_BRAND_CONSOLE}.l10n.msi ${BRANDING_BRAND_CONSOLE}.l10n.zh-tw.msi zh-tw.mst
cd ${WIX} && wscript WiSubStg.vbs ${BRANDING_BRAND_CONSOLE}.l10n.msi ja-jp.mst 1041
cd ${WIX} && wscript WiSubStg.vbs ${BRANDING_BRAND_CONSOLE}.l10n.msi zh-cn.mst 2052
cd ${WIX} && wscript WiSubStg.vbs ${BRANDING_BRAND_CONSOLE}.l10n.msi zh-tw.mst 1028
#sign again the combined msi because it seems the embedding breaks the signature
cd ${WIX} && chmod a+rw ${BRANDING_BRAND_CONSOLE}.l10n.msi && ${REPO}/sign.bat ${BRANDING_BRAND_CONSOLE}.l10n.msi

#create bundle exe installers - msi installers embedded
cp ${WIX}/out${BRANDING_BRAND_CONSOLE}/${BRANDING_BRAND_CONSOLE}.msi ${DOTNETINST}
cp ${WIX}/${BRANDING_BRAND_CONSOLE}.l10n.msi ${DOTNETINST}

cd ${DOTNETINST} && ./InstallerLinker.exe "/Output:${BRANDING_BRAND_CONSOLE}Setup.exe" "/Template:dotNetInstaller.exe" "/Configuration:XenCenterSetupBootstrapper.xml" "/e+" "/v+"
cd ${DOTNETINST} && ./InstallerLinker.exe "/Output:${BRANDING_BRAND_CONSOLE}Setup.l10n.exe" "/Template:dotNetInstaller.exe" "/Configuration:XenCenterSetupBootstrapper_l10n.xml" "/e+" "/v+"

sign_files()
{
	for file in $1
	do
		chmod a+rw ${file} && ${REPO}/sign.bat ${file}
	done
}
sign_files "${BRANDING_BRAND_CONSOLE}Setup.exe ${BRANDING_BRAND_CONSOLE}Setup.l10n.exe"

#create VNCCntrol installer
compile_installer "VNCControl" "en-us" && sign_msi "VNCControl"

set +u

#!/bin/bash
POSITIONAL=()
extension=""
user_def="pi"
port_def=1001
currPath=$(pwd)
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -c|--computer)
      computer="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--port)
      port="$2"
      shift # past argument
      shift # past value
      ;;
    -u|--user)
      user="$2"
      shift # past argument
      shift # past value
      ;;
    -l|--local)
      localPath="$2"
      shift # past argument
      shift # past value
      ;;
    -r|--remote)
      remotePath="$2"
      shift # past argument
      shift # past value
      ;;
    -e|--extension)
      extension="$2"
      shift # past argument
      shift # past value
      ;;
    -m|--makearg)
      makearg="$2"
      shift # past argument
      shift # past value
      ;;
    -?|-h|--help)
      echo 'bash gitsend.sh [non-switched arguments in order (computer port user extension)]'

	  if [[ $computer == "" ]]
	  then
      echo -e "\e[31m-c|--computer  \e[32mRemote device address    \e[33mm2m.local.com"
	  else
      echo -e "\e[31m-c|--computer  \e[32mRemote device address    \e[33$computer"
	  fi

	  if [[ $port == "" ]]
	  then
      echo -e "\e[31m-p|--port      \e[32mThe port number          \e[33m$port_def"
	  else
      echo -e "\e[31m-p|--port      \e[32mThe port number          \e[33m$port"
	  fi

	  if [[ $user == "" ]]
	  then
      echo -e "\e[31m-u|--user      \e[32mThe user name            \e[33m$user_def"
	  else
      echo -e "\e[31m-u|--user      \e[32mThe user name            \e[33m$user"
	  fi

	  if [[ $localPath == "" ]]
	  then
      echo -e "\e[31m-l|--local     \e[32mThe local directory      \e[33m$(pwd)"
	  else
      echo -e "\e[31m-l|--local     \e[32mThe local directory      \e[33m$localPath"
	  fi

	  if [[ $remotePath == "" ]]
	  then
      echo -e "\e[31m-r|--remote    \e[32mNo remotePath specified. \e[33mi.e. /home/pi/Projects/Local, \e[35mdo not use '~'!"
	  else
      echo -e "\e[31m-r|--remote    \e[32mThe remote directory     \e[33m$remotePath"
	  fi
	  
	  if [[ $extension == "" ]]
	  then
      echo -e "\e[31m-e|--extension \e[32mextension                \e[33m\"\.c\" for c files\e[0m"
	  else
      echo -e "\e[31m-e|--extension \e[32mextension                \e[33m$extension\e[0m"
	  fi
      echo -e "\e[31m-m|--makearg   \e[32mMake argument            \e[33mmakearg='$makearg' (build(default),clean,rebuild,logclean)\e[0m"

      exit 0 
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

if [[ $remotePath == "" ]]
then
 echo -e "\e[34;47mRemote path should be specified i.e. ~/Projects/Local\e[0m"
 exit 0
fi

set -- "${POSITIONAL[@]}" # restore positional parameters
if [[ $computer == "" ]]
then
 # Here computer is empty check the first argument
 if [[ $1 == "" ]]
 then
  # Argument is empty just get from stdin
  echo Enter remote computer address
  read computer
 else
  # Assign argument to computer and shift argument
  computer=$1
  shift
 fi
fi

if [[ $port == "" ]]
then
# Here port is empty check the first argument
 if [[ $1 == "" ]]
 then
  # Argument is empty use default
  port=1001
 else
  # Assign argument to port and shift argument
  port=$1
  shift
 fi
fi

if [[ $user == "" ]]
then
 # Here user is empty check the first argument
 if [[ $1 == "" ]]
 then
  # Argument is empty use default
  user=pi
 else
  # Assign argument to user and shift argument
  user=$1
  shift
 fi
fi



if [[ $localPath == "" ]]
then
 localPath=$currPath
else
 cd $localPath
fi

if [[ $extension != "" ]]
then
 # Assign argument to port and shift argument
 fileName=$(git status | sed -n "s/^.*modified:\s*\(.*$extension$\).*/\1 /p")
 fileName=$(echo "$fileName" | sed ':a;N;$!ba;s/\n/ /g')
else
if [[ $1 != "" ]]
then
 # Assign argument to port and shift argument
 fileName=$@
fi 
fi

patchName='local.patch'
echo -e '\e[31;1m'
echo 'Computer     :'  $computer
echo 'Port         :'  $port
echo 'User Name    :'  $user
echo 'Source File  :'  $fileName
echo 'Local Path   :'  $localPath
echo 'Remote Path  :'  $remotePath
echo 'Current Path :'  $currPath
echo 'ARGS         :'  ${POSITIONAL[@]}
echo -e '\e[0m'

echo -e '\e[34mModified files\e[35m'
git status | sed -n "s/^.*modified:\s*\(.*$extension\).*/\1 /p"
echo -e '\e[0m'


if [[ $fileName == "" ]]
then
 # Create patch locally
 git diff > $patchName 
 # Send the patch to computer machine
 scp.exe -P $port -o 'StrictHostKeyChecking no' "$patchName" "$user@$computer:$remotePath/$patchName"
 # Purge computer diff, apply sent diff remotely, delete sent diff and make the project.
 echo ssh.exe -p $port "$user@$computer" "cd $remotePath/;git checkout .;git pull;git apply $patchName;make $makearg;" 
 ssh.exe -p $port "$user@$computer" "cd $remotePath/;git checkout .;git pull;git apply $patchName;make $makearg;" 
else
 # Create patch locally
 echo "git diff $fileName > $patchName"
 git diff $fileName > $patchName
 # Send the patch to computer machine
 echo "scp.exe -P $port -o 'StrictHostKeyChecking no' \"$patchName\" \"$user@$computer:$remotePath/$patchName\""
 scp.exe -P $port -o 'StrictHostKeyChecking no' "$patchName" "$user@$computer:$remotePath/$patchName"
 # Purge computer diff, apply sent diff remotely, delete sent diff and make the project.
 echo "ssh.exe -p $port \"$user@$computer\" \"cd $remotePath/;git checkout $fileName;git apply $patchName;make $makearg;\""
 ssh.exe -p $port "$user@$computer" "cd $remotePath/;git checkout $fileName;git apply $patchName;make $makearg;" 
fi

cd $currPath

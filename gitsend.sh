#!/bin/bash
POSITIONAL=()
extension=""
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
    -e|--extension)
      extension="$2"
      shift # past argument
      shift # past value
      ;;
    -?|-h|--help)
      echo 'bash gitsend.sh [non-switched arguments in order (computer port user extension)]'
      echo -e '\e[31m-c|--computer  \e[32mRemote device address i.e m2m.local.com'
      echo -e '\e[31m-p|--port      \e[32mport number default: 1001'
      echo -e '\e[31m-u|--user      \e[32muser default:pi'
      echo -e '\e[31m-e|--extension \e[32mextension i.e. "\.c" for c files\e[0m'
      exit 0 
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
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
echo 'Computer    :'  $computer
echo 'Port        :'  $port
echo 'User Name   :'  $user
echo 'Source File :'  $fileName
echo 'ARGS        :'  ${POSITIONAL[@]}
echo -e '\e[0m'

echo -e '\e[34mModified files\e[35m'
git status | sed -n "s/^.*modified:\s*\(.*$extension\).*/\1 /p"
echo -e '\e[0m'

if [[ $fileName == "" ]]
then
 # Create patch locally
 git diff > $patchName 
 # Send the patch to computer machine
 scp.exe -P $port -o 'StrictHostKeyChecking no' "$patchName" "$user@$computer:~/Projects/Local/$patchName"
 # Purge computer diff, apply sent diff remotely, delete sent diff and make the project.
 echo ssh.exe -p $port "$user@$computer" "cd ~/Projects/Local/;git checkout .;git pull;git apply $patchName;make;" 
 ssh.exe -p $port "$user@$computer" "cd ~/Projects/Local/;git checkout .;git pull;git apply $patchName;make;" 

else
 # Create patch locally
 echo "git diff $fileName > $patchName"
 git diff $fileName > $patchName
 # Send the patch to computer machine
 echo "scp.exe -P $port -o 'StrictHostKeyChecking no' \"$patchName\" \"$user@$computer:~/Projects/Local/$patchName\""
 scp.exe -P $port -o 'StrictHostKeyChecking no' "$patchName" "$user@$computer:~/Projects/Local/$patchName"
 # Purge computer diff, apply sent diff remotely, delete sent diff and make the project.
 echo "ssh.exe -p $port \"$user@$computer\" \"cd ~/Projects/Local/;git checkout $fileName;git apply $patchName;make;\""
 ssh.exe -p $port "$user@$computer" "cd ~/Projects/Local/;git checkout $fileName;git apply $patchName;make;" 
fi
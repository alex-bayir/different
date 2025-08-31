#!/bin/bash
User=scanner
Group=$User
UserID=1111
GroupID=$UserID
UserDir=/home/$User
SSHDir=$UserDir/.ssh
UserPubKeyFile=$SSHDir/authorized_keys
PWDFile=/etc/passwd
GRPFile=/etc/group
SHDFile=/etc/shadow
SUDOFile=/etc/sudoers
UserPubKey='<ssh key algorithm> <ssh public key> vulnerability scanner user'
PWDString=$User:x:1111:1111::/home/scanner:/bin/bash
GRPString=$Group:x:1111:
SHDString=$User:!!:19979::::::
SUDOString=$User' ALL=(root)NOPASSWD:ALL'

if [[ "$(whoami)" != root ]] ; then
	echo There are not enough privileges to execute.; exit 1
fi

if grep -q $UserID $PWDFile ; then
	echo The object with the ID $UserID already exists.; exit 1
fi

if grep -q $GroupID $GRPFile ; then
	echo The group with the ID $GroupID already exists.; exit 1
fi

if grep -q $User $SHDFile ; then
    echo The user named $User already exists.; exit 1
fi

if echo $PWDString>>$PWDFile ; then
	echo The $PWDFile file has been changed.
else
	echo Error writing to $PWDFile.; exit 1
fi

if echo $GRPString>>$GRPFile ; then
	echo The $GRPFile file has been changed.
else
	echo Error writing to $GRPFile.; exit 1
fi

if echo $SHDString>>$SHDFile ; then
	echo The $SHDFile file has been changed.
else
	echo Error writing to $SHDFile.; exit 1
fi

if [ ! -d $UserDir ] ; then
	if mkdir $UserDir && chown $User:$User $UserDir && chmod 700 $UserDir ; then
		echo The $UserDir directory has been created.
	else
		echo Error creating $UserDir.; exit 1
	fi
else
	echo The $UserDir already exist.
fi

if [ ! -d $SSHDir ] ; then
	if mkdir $SSHDir && chown $User:$User $SSHDir && chmod 700 $SSHDir ; then
		echo The $SSHDir directory has been created.
	else
		echo Error creating $SSHDir.; exit 1
	fi
else
	echo The $SSHDir already exist.
fi

if  echo $UserPubKey > $UserPubKeyFile && chown $User:$User $UserPubKeyFile && chmod 600 $UserPubKeyFile ; then
	echo The key for $User is set.
else
	echo Error installing the key for $User.; exit 1
fi

if grep -q $User $SUDOFile ; then
	echo The entry for $User in $SUDOFile already exists.; exit 1
fi

if echo $SUDOString>>$SUDOFile ; then
	echo The $SUDOFile file has been changed.
else
	echo Error writing to $SUDOFile.; exit 1
fi

echo The setup is complete.

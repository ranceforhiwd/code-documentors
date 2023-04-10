if [ -e config.conf ]; then
    # Convert the file into an array of strings
    lines=(`cat "config_sample.conf"`)

    # Assign lines via array index to userdefine veriables
    username=${lines[0]}
    password=${lines[1]}
    jsdocContainerName=${lines[3]}$(date "+%Y.%m.%d-%H.%M.%S")
    directoryToCloneRepo=${lines[5]}
    sourceRepoBranch=${lines[6]}
    sourceRepo=${lines[7]}
    repoUrl=${lines[8]}
    echo $directoryToCloneRepo
else
    echo "config_sample.conf file doesn't exit.." 
fi
    #Prepare file structure
    rm -rf $directoryToCloneRepo
    mkdir $directoryToCloneRepo
    cd $directoryToCloneRepo || { printf "cd failed, exiting\n" >&2;  return 1; }
    #Pull source code to document
    echo "Starting to clone.."
    git clone -b $sourceRepoBranch https://$username:$password@$repoUrl/$sourceRepo
    echo "Sucessfully clone.."
    sleep 2.0
    #Begin PHP Docs
    echo "Generating documention.."
    docker run --rm -v ${PWD}:/data phpdoc/phpdoc:3 run --force -i ./$sourceRepo/vendor -t phpout --sourcecode
    echo "Sucessfully generated the php document"
    sleep 1.5
    #Begin JS Docs
    docker run -it -d --name=$jsdocContainerName -v ${PWD}/:/data cm0x4d/jsdoc
    docker exec -it $jsdocContainerName sh data/$sourceRepo/makejs.sh
    echo "Sucessfully generated the js document"
    #Begin Documentation repo updates
    git clone -b master https://$repoUrl/phpdocs  
    cp -r phpout/* phpdocs/
    sleep 1.5
    cd phpdocs
    git add .
    git commit -m "phpdoc project$(date "+%Y.%m.%d-%H.%M.%S")"
    sleep 1.5
    git pull --rebase origin master
    sleep 1.5
    git push -f origin master
    sleep 1.5
    echo "Pushed php web pages documention to phpdocs repo.."
    cd ../
    git clone -b master https://$repoUrl/jsdocs
    cp out/*.* jsdocs/
    cd jsdocs
    git add .
    git commit -m "jsdocs project$(date "+%Y.%m.%d-%H.%M.%S")"
    sleep 1.5
    git pull --rebase origin master
    sleep 1.5
    git push -f origin master
    sleep 1.5
    echo "Pushed php web pages documention to jsdocs repo.."    
    sleep 1.5
    docker stop $jsdocContainerName
    sleep 1.5
    docker rm -v $jsdocContainerName
    echo "End of execution"
    echo ${PWD}
    cd ../
    cd phpout
    docker run -d -p 591:80 -v ${PWD}:/var/www/html bitbull/webserver
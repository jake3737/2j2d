#!/usr/bin/env sh

set -e

get_by_git(){
    mkdir -p ~/jd_scripts/logs
    cp -f docker-compose.yml ~/jd_scripts/
    cd ~/jd_scripts/

    docker-compose up -d

    echo "git pull拉取最新代码..."
    docker exec -i jd_scripts /bin/sh -c "git clone $REPO_URL /scriptss"

    sudo cp -rf `sudo find /var/lib/docker -type d -name "scriptss" | grep merged` ~/

    cd ~/scriptss
    #UPSTREAM_REPO=`git remote -v | grep origin | grep fetch | awk '{print $2}'`
    git remote --verbose

    echo "Resetting origin to: https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
    sudo git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
    git remote --verbose

    echo "Pushing changings from tmp_upstream to origin"
    sudo git push origin "refs/remotes/origin/${SOURCE_BRANCH}:refs/heads/${DESTINATION_BRANCH}" --force

    git remote --verbose
}

get_by_docker(){
    docker rmi `docker images -q`
    echo "Get docker image"
    docker pull $SOURCE_IMAGE
    docker save `docker images | grep latest | grep -v grep | awk '{print $3}'` > ~/jd.tar
    [ ! -e ~/scripts ] && mkdir ~/scripts && tar xvf ~/jd.tar -C ~/scripts

    echo "Find layer"
    for file in `ls ~/scripts`
    do
      layer_size=`ls -l ~/scripts/$file 2> /dev/null | grep layer | grep -v grep | awk '{print $5}'`
      [ "$layer_size" -gt 52428800 ] && tar xvf ~/scripts/$file/layer.tar -C ~/scripts/ > /dev/null && break
    done

    cd ~/scripts/scripts/
    SOURCE_BRANCH=`git branch | awk '{print $2}'`
    UPSTREAM_REPO=`git remote -v | grep origin | grep fetch | awk '{print $2}'`

    echo "Resetting origin to: https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
    git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
    git remote --verbose

    echo "Pushing changings from tmp_upstream to origin"
    git push origin "refs/remotes/origin/${SOURCE_BRANCH}:refs/heads/${DESTINATION_BRANCH}" --force

    git remote --verbose
}
get_by_docker

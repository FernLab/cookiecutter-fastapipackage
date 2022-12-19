#!/usr/bin/env bash
set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately

context_dir="./context"
dockerfile="{{ cookiecutter.project_slug }}_ci.docker"
python_script='
version = {}
with open("../../{{ cookiecutter.project_slug }}/version.py") as version_file:
    exec(version_file.read(), version)
print(version["__version__"])
'
version=`python -c "$python_script"`
tag="{{ cookiecutter.project_slug }}_ci:$version"
gitlab_runner="{{ cookiecutter.project_slug }}_gitlab_CI_runner"

echo "#### Build runner docker image"
if [[ "$(docker images ${tag} | grep ${tag} 2> /dev/null)" != "" ]]; then
  docker rmi ${tag}
fi
docker build ${context_dir} \
    --no-cache \
    -f ${context_dir}/${dockerfile} \
    -m 20G \
    -t ${tag}

# create the gitlab-runner docker container for the current project
# NOTE: The 'gitlab-runner' and 'gitlab-ci-multi-runner' services will run within this container.
#       The runner uses a 'config.toml' configuration file at /etc/gitlab-runner within the container which can be
#       modified through additional parameters of the 'gitlab-runner register' command.
echo "#### Create gitlab-runner (daemon) container with tag; ${tag}"
if [ "$(docker ps -qa -f name=${gitlab_runner})" ]; then
    if [ "$(docker ps -q -f name=${gitlab_runner})" ]; then
        docker stop ${gitlab_runner};
    fi
    docker rm ${gitlab_runner};
fi
docker run \
    -d \
    --name ${gitlab_runner} \
    --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    gitlab/gitlab-runner:latest

# register the runner at the corresponding GitLab repository via a registration-token
echo "#### Register container at gitlab, get token here https://git.gfz-potsdam.de/<group>/{{ cookiecutter.project_slug }}/-/settings/ci_cd"
read -p "Please enter gitlab token: " token
echo ""
read -p "Please enter gitlab runner name: " runner_name
echo "New gitlab runner image will named  ${gitlab_runner}"
# NOTE: In case of locally stored images (like here), the docker pull policy 'never' must be used
#       (see https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work).
docker exec -it ${gitlab_runner} /bin/bash -c    "\
export RUNNER_EXECUTOR=docker && \
gitlab-ci-multi-runner register \
  --non-interactive \
  --executor 'docker' \
  --docker-image '${tag}' \
  --url 'https://git.gfz-potsdam.de/ci' \
  --registration-token '${token}' \
  --description '${runner_name}' \
  --tag-list {{ cookiecutter.project_slug }}_ci_client \
  --run-untagged='true' \
  --locked='true' \
  --access-level='not_protected' \
  --docker-pull-policy='never'
  "
ls

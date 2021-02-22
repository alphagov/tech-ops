FROM hashicorp/terraform:0.12.29 AS task-toolbox

RUN apk add --update \
	curl \
	git \
	wget \
	unzip \
	jq \
	openssh \
	ruby \
	bash \
	openssl \
	file \
	tar \
	netcat-openbsd \
	groff \
	less \
	python3 \
	py3-pip \
	mailcap \
	ncurses \
	gnupg \
	rpm \
	&& pip3 install awscli s3cmd yq PyYAML \
	&& rm /var/cache/apk/*

COPY bin/aws-assume-role /usr/local/bin/

ENTRYPOINT ["/bin/bash"]
CMD []

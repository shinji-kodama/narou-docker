FROM ruby:3.4-slim

LABEL maintainer="whiteleaf <2nd.leaf@gmail.com>"

ENV NAROU_VERSION=3.9.1
ENV AOZORAEPUB3_VERSION=1.1.0b55Q
ENV AOZORAEPUB3_FILE=AozoraEpub3-${AOZORAEPUB3_VERSION}

# フォーク先のリポジトリ・ブランチを指定する場合は以下の環境変数を設定
ENV NAROU_REPOSITORY="https://github.com/etg-lt/narou"
ENV NAROU_BRANCH="patch-3"

WORKDIR /temp

# 日本のミラーサーバーを使用する
# RUN sed -i.bak -e "s/http:\/\/deb\.debian\.org\/debian$/http:\/\/ftp\.\jp\.debian\.org\/debian/g" /etc/apt/sources.list.d/debian.sources

RUN set -x \
     ###############################
     # Install required packages
     ###############################
     && apt-get update \
     && apt-get install -y wget unzip \
      default-jre \
     #  openjdk-8-jre \
      build-essential make gcc git \
     #
     #############################
     # install AozoraEpub3
     #############################
     && wget https://github.com/kyukyunyorituryo/AozoraEpub3/releases/download/${AOZORAEPUB3_VERSION}/${AOZORAEPUB3_FILE}.zip \
     && mkdir /aozoraepub3 \
     && unzip -q ${AOZORAEPUB3_FILE}.zip -d /aozoraepub3 \
     #
     #################################
     # 必要なgemのインストール
     #################################
     && gem install 'erubi:1.13' 'specific_install:0.3.8' --no-document \
     #
     #############################
     # install Narou.rb
     #############################
     # ! 通常のnarou.rbをインストールする場合はこちらを有効にする
     # && gem install narou -v ${NAROU_VERSION} --no-document \
     #
     # ! narou.rbの特定リポジトリとブランチを指定してインストールする場合はこちらを有効にする
     && gem specific_install -l ${NAROU_REPOSITORY} -b ${NAROU_BRANCH} \
     #
     # tilt/erubisの読み込み失敗対応
     # erubis読み込み部分をerubiに書き換えて代用
     && sed -ie "s/tilt\/erubis/tilt\/erubi/g" /usr/local/bundle/gems/narou-${NAROU_VERSION}/lib/web/appserver.rb \
     ##############################
     # 不要なパッケージを削除
     ##############################
     # specific_installを削除
     && gem uninstall specific_install --all \
     && apt-get purge -y build-essential make gcc git \
     && apt-get autoremove -y \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/* \
     #
     #############################
     # setting AozoraEpub3
     #############################
     && mkdir .narousetting \
     && narou init -p /aozoraepub3/${AOZORAEPUB3_VERSION} -l 1.8 \
     && rm -rf /temp

WORKDIR /novel

COPY ./init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 33000-33001

ENTRYPOINT ["init.sh"]
CMD ["narou", "web", "-np", "33000"]

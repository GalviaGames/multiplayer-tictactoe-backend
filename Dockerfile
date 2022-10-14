FROM heroiclabs/nakama:3.13.1

ARG PGUSER
ENV PGUSER=${PGUSER}

ARG PGHOST
ENV PGHOST=${PGHOST}

ARG PGPORT
ENV PGPORT=${PGPORT}

COPY /modules /nakama/data/modules
COPY /entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD []
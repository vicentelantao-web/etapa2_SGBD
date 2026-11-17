-- ============================================================================
-- SIBD 2026/2027 - Projeto - Etapa 2
-- Grupo 33
--
-- Alunos:
--   fc65633  Martim Pereira         Turma 14
--   fc65607  Vicente Antão          Turma 14
--   fc65675  Miguel Caiado          Turma 14
--
-- Contribuições:
--   Martim Pereira (33%):traduçao das tabelas de pessoas e veículos.
--   Vicente Antão 33%):tabelas de posse, turno e pedido.
--   Miguel Caiado (33%):dados de exemplo e a revisão das restrições.
-- ============================================================================
--
-- Notas sobre a tradução do diagrama:
--
-- * As partes a cinzento (Morada, Mora, Base, Fica, Afeto, Dispõe e Local)
--   não são traduzidas. Por isso, não se aplicam as RIA-02, RIA-29, RIA-30,
--   RIA-31, RIA-35 e RIA-36.
--
-- * A entidade Data (atributo Valor) só serve para pôr a data de início
--   ("Desde") na chave das associações Possui, Turno e Atribuído. Não tem
--   informação própria, por isso não dá origem a uma tabela: a data passa a
--   ser uma coluna das tabelas posse, turno e pedido.
--
-- * A associação Atribuído tem restrição de chave do lado do Pedido de
--   Assistência (cada pedido é atribuído no máximo a um turno), por isso é
--   traduzida para colunas opcionais da tabela pedido. Isto permite suportar
--   as RIA-14, RIA-16, RIA-39 e RIA-40 com restrições CHECK.
--
-- * A associação Para tem restrição de chave e de participação total do lado
--   do Pedido de Assistência, por isso é traduzida para uma coluna obrigatória
--   da tabela pedido.
--
-- Restrições de integridade não suportadas:
--
-- * RIA-01: O veículo de um pedido de assistência tem de ser possuído pelo
--   sócio que faz o pedido no momento do pedido.
-- * RIA-03: Sócio AND Mecânico COVER Pessoa.
-- * RIA-05: Veículo de Sócio AND Veículo de Assistência COVER Veículo.
-- * Veículo de Sócio e Veículo de Assistência são disjuntos (não há
--   restrição OVERLAPS entre eles no diagrama).
-- * RIA-06: A data de nascimento tem de ser 16 ou mais anos anterior à data
--   atual (o Oracle não permite SYSDATE em restrições CHECK).
-- * RIA-07: O ano de fabrico de um veículo tem de ser anterior ou igual ao
--   ano atual (o Oracle não permite SYSDATE em restrições CHECK).
-- * RIA-09: Os períodos de posse de um mesmo veículo por um mesmo sócio não
--   se podem intersetar.
-- * RIA-11: Os turnos de um mesmo mecânico não se podem intersetar.
-- * RIA-12: Um veículo de assistência não pode ser usado em simultâneo em
--   dois turnos.
-- * RIA-13: A data de um pedido tem de estar dentro de um período de posse
--   desse veículo por esse sócio.
-- * RIA-15: A data de início de uma assistência tem de ser posterior à data
--   de início do turno atribuído.
-- * RIA-17: A data de fim de uma assistência tem de ser anterior à data de
--   fim do turno atribuído.
-- * Participação total de Sócio em Possui: cada sócio possui pelo menos um
--   veículo.
-- * Participação total de Veículo de Sócio em Possui: cada veículo de sócio
--   é possuído por pelo menos um sócio.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- DROP TABLE
-- ----------------------------------------------------------------------------

DROP TABLE pedido              CASCADE CONSTRAINTS;
DROP TABLE turno               CASCADE CONSTRAINTS;
DROP TABLE posse               CASCADE CONSTRAINTS;
DROP TABLE veiculo_assistencia CASCADE CONSTRAINTS;
DROP TABLE veiculo_socio       CASCADE CONSTRAINTS;
DROP TABLE veiculo             CASCADE CONSTRAINTS;
DROP TABLE mecanico            CASCADE CONSTRAINTS;
DROP TABLE socio               CASCADE CONSTRAINTS;
DROP TABLE pessoa              CASCADE CONSTRAINTS;


-- ----------------------------------------------------------------------------
-- CREATE TABLE
-- ----------------------------------------------------------------------------

CREATE TABLE pessoa (
  nif        NUMBER(9),
  nome       VARCHAR2(80) CONSTRAINT nn_pessoa_nome       NOT NULL,
  nic        NUMBER(8)    CONSTRAINT nn_pessoa_nic        NOT NULL,
  nascimento DATE         CONSTRAINT nn_pessoa_nascimento NOT NULL,
  genero     VARCHAR2(9)  CONSTRAINT nn_pessoa_genero     NOT NULL,
  telemovel  NUMBER(9)    CONSTRAINT nn_pessoa_telemovel  NOT NULL,
--
  CONSTRAINT pk_pessoa
    PRIMARY KEY (nif),
--
  CONSTRAINT un_pessoa_nic                                 -- RIA-18
    UNIQUE (nic),
--
  CONSTRAINT un_pessoa_telemovel                           -- RIA-19
    UNIQUE (telemovel),
--
  CONSTRAINT ck_pessoa_nif                                 -- RIA-23
    CHECK (nif BETWEEN 100000000 AND 999999999),
--
  CONSTRAINT ck_pessoa_nic                                 -- RIA-24
    CHECK (nic BETWEEN 1 AND 99999999),
--
  CONSTRAINT ck_pessoa_genero                              -- RIA-25
    CHECK (genero IN ('Feminino', 'Masculino', 'Outro')),
--
  CONSTRAINT ck_pessoa_telemovel                           -- RIA-26
    CHECK (telemovel BETWEEN 910000000 AND 939999999
        OR telemovel BETWEEN 960000000 AND 969999999)
);

CREATE TABLE socio (
  nif    NUMBER(9),
  numero NUMBER(6) CONSTRAINT nn_socio_numero NOT NULL,
--
  CONSTRAINT pk_socio
    PRIMARY KEY (nif),
--
  CONSTRAINT fk_socio_pessoa
    FOREIGN KEY (nif) REFERENCES pessoa (nif) ON DELETE CASCADE,
--
  CONSTRAINT un_socio_numero                               -- RIA-20
    UNIQUE (numero),
--
  CONSTRAINT ck_socio_numero                               -- RIA-27
    CHECK (numero BETWEEN 1 AND 999999)
);

CREATE TABLE mecanico (
  nif           NUMBER(9),
  num_empregado NUMBER(5) CONSTRAINT nn_mecanico_num_empregado NOT NULL,
--
  CONSTRAINT pk_mecanico
    PRIMARY KEY (nif),
--
  CONSTRAINT fk_mecanico_pessoa
    FOREIGN KEY (nif) REFERENCES pessoa (nif) ON DELETE CASCADE,
--
  CONSTRAINT un_mecanico_num_empregado                     -- RIA-21
    UNIQUE (num_empregado),
--
  CONSTRAINT ck_mecanico_num_empregado                     -- RIA-28
    CHECK (num_empregado BETWEEN 1 AND 99999)
);

CREATE TABLE veiculo (
  matricula CHAR(8),
  marca     VARCHAR2(40) CONSTRAINT nn_veiculo_marca  NOT NULL,
  modelo    VARCHAR2(40) CONSTRAINT nn_veiculo_modelo NOT NULL,
  ano       NUMBER(4)    CONSTRAINT nn_veiculo_ano    NOT NULL,
  tipo      VARCHAR2(9)  CONSTRAINT nn_veiculo_tipo   NOT NULL,
--
  CONSTRAINT pk_veiculo
    PRIMARY KEY (matricula),
--
  CONSTRAINT ck_veiculo_matricula                          -- RIA-32
    CHECK (REGEXP_LIKE(matricula, '^([A-Z]{2}-[0-9]{2}-[0-9]{2}'
                                || '|[0-9]{2}-[0-9]{2}-[A-Z]{2}'
                                || '|[0-9]{2}-[A-Z]{2}-[0-9]{2}'
                                || '|[A-Z]{2}-[0-9]{2}-[A-Z]{2})$')),
--
  CONSTRAINT ck_veiculo_ano
    CHECK (ano >= 1900),
--
  CONSTRAINT ck_veiculo_tipo                               -- RIA-33
    CHECK (tipo IN ('Automóvel', 'Moto'))
);

CREATE TABLE veiculo_socio (
  matricula CHAR(8),
  cor       VARCHAR2(20) CONSTRAINT nn_veiculo_socio_cor NOT NULL,
--
  CONSTRAINT pk_veiculo_socio
    PRIMARY KEY (matricula),
--
  CONSTRAINT fk_veiculo_socio_veiculo
    FOREIGN KEY (matricula) REFERENCES veiculo (matricula)
    ON DELETE CASCADE
);

CREATE TABLE veiculo_assistencia (
  matricula CHAR(8),
  numero    NUMBER(4) CONSTRAINT nn_veiculo_assist_numero NOT NULL,
--
  CONSTRAINT pk_veiculo_assistencia
    PRIMARY KEY (matricula),
--
  CONSTRAINT fk_veiculo_assist_veiculo
    FOREIGN KEY (matricula) REFERENCES veiculo (matricula)
    ON DELETE CASCADE,
--
  CONSTRAINT un_veiculo_assist_numero                      -- RIA-22
    UNIQUE (numero),
--
  CONSTRAINT ck_veiculo_assist_numero                      -- RIA-34
    CHECK (numero BETWEEN 1 AND 9999)
);

CREATE TABLE posse (
  socio   NUMBER(9),
  veiculo CHAR(8),
  desde   DATE,
  ate     DATE,
--
  CONSTRAINT pk_posse
    PRIMARY KEY (socio, veiculo, desde),
--
  CONSTRAINT fk_posse_socio
    FOREIGN KEY (socio) REFERENCES socio (nif),
--
  CONSTRAINT fk_posse_veiculo
    FOREIGN KEY (veiculo) REFERENCES veiculo_socio (matricula),
--
  CONSTRAINT ck_posse_periodo                              -- RIA-08
    CHECK (ate IS NULL OR ate > desde)
);

CREATE TABLE turno (
  mecanico NUMBER(9),
  veiculo  CHAR(8),
  desde    DATE,
  ate      DATE CONSTRAINT nn_turno_ate NOT NULL,
--
  CONSTRAINT pk_turno
    PRIMARY KEY (mecanico, veiculo, desde),
--
  CONSTRAINT fk_turno_mecanico
    FOREIGN KEY (mecanico) REFERENCES mecanico (nif),
--
  CONSTRAINT fk_turno_veiculo
    FOREIGN KEY (veiculo) REFERENCES veiculo_assistencia (matricula),
--
  CONSTRAINT ck_turno_periodo                              -- RIA-10
    CHECK (desde < ate)
);

CREATE TABLE pedido (
  socio          NUMBER(9),
  numero_seq     NUMBER(6),
  veiculo        CHAR(8)       CONSTRAINT nn_pedido_veiculo  NOT NULL,
  data_pedido    DATE          CONSTRAINT nn_pedido_data     NOT NULL,
  problema       VARCHAR2(200) CONSTRAINT nn_pedido_problema NOT NULL,
  estado         VARCHAR2(30)  DEFAULT 'ASSISTÊNCIA PEDIDA'
                               CONSTRAINT nn_pedido_estado   NOT NULL,
  turno_mecanico NUMBER(9),
  turno_veiculo  CHAR(8),
  turno_desde    DATE,
  assist_desde   DATE,
  assist_ate     DATE,
--
  CONSTRAINT pk_pedido
    PRIMARY KEY (socio, numero_seq),
--
  CONSTRAINT fk_pedido_socio                               -- Faz
    FOREIGN KEY (socio) REFERENCES socio (nif) ON DELETE CASCADE,
--
  CONSTRAINT fk_pedido_veiculo                             -- Para
    FOREIGN KEY (veiculo) REFERENCES veiculo_socio (matricula),
--
  CONSTRAINT fk_pedido_turno                               -- Atribuído
    FOREIGN KEY (turno_mecanico, turno_veiculo, turno_desde)
    REFERENCES turno (mecanico, veiculo, desde),
--
  CONSTRAINT ck_pedido_numero_seq                          -- RIA-37
    CHECK (numero_seq >= 1),
--
  CONSTRAINT ck_pedido_estado                              -- RIA-38
    CHECK (estado IN ('ASSISTÊNCIA PEDIDA',
                      'ASSISTÊNCIA EM CURSO',
                      'ASSISTÊNCIA CONCLUÍDA')),
--
  CONSTRAINT ck_pedido_atribuicao                          -- Atribuído
    CHECK ((turno_mecanico IS NULL AND turno_veiculo IS NULL AND
            turno_desde IS NULL AND assist_desde IS NULL AND
            assist_ate IS NULL)
        OR (turno_mecanico IS NOT NULL AND turno_veiculo IS NOT NULL AND
            turno_desde IS NOT NULL AND assist_desde IS NOT NULL)),
--
  CONSTRAINT ck_pedido_assist_inicio                       -- RIA-14
    CHECK (assist_desde IS NULL OR assist_desde > data_pedido),
--
  CONSTRAINT ck_pedido_assist_fim                          -- RIA-16
    CHECK (assist_ate IS NULL OR assist_ate > assist_desde),
--
  CONSTRAINT ck_pedido_em_curso                            -- RIA-39
    CHECK (estado <> 'ASSISTÊNCIA EM CURSO' OR assist_desde IS NOT NULL),
--
  CONSTRAINT ck_pedido_concluida                           -- RIA-40
    CHECK (estado <> 'ASSISTÊNCIA CONCLUÍDA' OR assist_ate IS NOT NULL)
);


-- ----------------------------------------------------------------------------
-- INSERT INTO
-- ----------------------------------------------------------------------------

INSERT INTO pessoa (nif, nome, nic, nascimento, genero, telemovel)
     VALUES (123456789, 'Ana Silva', 12345678,
             TO_DATE('1990-05-12', 'YYYY-MM-DD'), 'Feminino', 912345678);

INSERT INTO pessoa (nif, nome, nic, nascimento, genero, telemovel)
     VALUES (234567890, 'Bruno Costa', 23456789,
             TO_DATE('1985-11-03', 'YYYY-MM-DD'), 'Masculino', 935551234);

INSERT INTO pessoa (nif, nome, nic, nascimento, genero, telemovel)
     VALUES (345678901, 'Carla Mendes', 3456789,
             TO_DATE('1998-02-20', 'YYYY-MM-DD'), 'Feminino', 961112233);

INSERT INTO pessoa (nif, nome, nic, nascimento, genero, telemovel)
     VALUES (456789012, 'Duarte Rocha', 45678901,
             TO_DATE('2001-07-30', 'YYYY-MM-DD'), 'Outro', 927778899);

-- O Bruno Costa é sócio e mecânico (RIA-04).
INSERT INTO socio (nif, numero) VALUES (123456789, 1);
INSERT INTO socio (nif, numero) VALUES (234567890, 2);
INSERT INTO socio (nif, numero) VALUES (456789012, 3);

INSERT INTO mecanico (nif, num_empregado) VALUES (234567890, 101);
INSERT INTO mecanico (nif, num_empregado) VALUES (345678901, 102);

INSERT INTO veiculo (matricula, marca, modelo, ano, tipo)
     VALUES ('AA-12-34', 'Renault', 'Clio', 2015, 'Automóvel');

INSERT INTO veiculo (matricula, marca, modelo, ano, tipo)
     VALUES ('12-34-BB', 'Honda', 'PCX', 2020, 'Moto');

INSERT INTO veiculo (matricula, marca, modelo, ano, tipo)
     VALUES ('56-CD-78', 'Peugeot', '208', 2019, 'Automóvel');

INSERT INTO veiculo (matricula, marca, modelo, ano, tipo)
     VALUES ('AB-12-CD', 'Ford', 'Transit', 2022, 'Automóvel');

INSERT INTO veiculo (matricula, marca, modelo, ano, tipo)
     VALUES ('BC-45-DE', 'Mercedes-Benz', 'Sprinter', 2023, 'Automóvel');

INSERT INTO veiculo_socio (matricula, cor) VALUES ('AA-12-34', 'Cinzento');
INSERT INTO veiculo_socio (matricula, cor) VALUES ('12-34-BB', 'Preto');
INSERT INTO veiculo_socio (matricula, cor) VALUES ('56-CD-78', 'Branco');

INSERT INTO veiculo_assistencia (matricula, numero) VALUES ('AB-12-CD', 1);
INSERT INTO veiculo_assistencia (matricula, numero) VALUES ('BC-45-DE', 2);

INSERT INTO posse (socio, veiculo, desde, ate)
     VALUES (123456789, 'AA-12-34',
             TO_DATE('2020-01-10 10:00', 'YYYY-MM-DD HH24:MI'), NULL);

INSERT INTO posse (socio, veiculo, desde, ate)
     VALUES (123456789, '56-CD-78',
             TO_DATE('2019-05-01 09:00', 'YYYY-MM-DD HH24:MI'),
             TO_DATE('2022-08-31 18:00', 'YYYY-MM-DD HH24:MI'));

-- O Bruno Costa teve a mesma moto em dois períodos diferentes (RIA-09).
INSERT INTO posse (socio, veiculo, desde, ate)
     VALUES (234567890, '12-34-BB',
             TO_DATE('2021-03-01 11:00', 'YYYY-MM-DD HH24:MI'),
             TO_DATE('2023-06-30 17:00', 'YYYY-MM-DD HH24:MI'));

INSERT INTO posse (socio, veiculo, desde, ate)
     VALUES (234567890, '12-34-BB',
             TO_DATE('2024-01-15 15:00', 'YYYY-MM-DD HH24:MI'), NULL);

INSERT INTO posse (socio, veiculo, desde, ate)
     VALUES (456789012, '56-CD-78',
             TO_DATE('2022-09-01 12:00', 'YYYY-MM-DD HH24:MI'), NULL);

INSERT INTO turno (mecanico, veiculo, desde, ate)
     VALUES (234567890, 'AB-12-CD',
             TO_DATE('2026-03-10 08:00', 'YYYY-MM-DD HH24:MI'),
             TO_DATE('2026-03-10 16:00', 'YYYY-MM-DD HH24:MI'));

INSERT INTO turno (mecanico, veiculo, desde, ate)
     VALUES (234567890, 'AB-12-CD',
             TO_DATE('2026-03-11 08:00', 'YYYY-MM-DD HH24:MI'),
             TO_DATE('2026-03-11 16:00', 'YYYY-MM-DD HH24:MI'));

INSERT INTO turno (mecanico, veiculo, desde, ate)
     VALUES (345678901, 'BC-45-DE',
             TO_DATE('2026-03-10 08:00', 'YYYY-MM-DD HH24:MI'),
             TO_DATE('2026-03-10 16:00', 'YYYY-MM-DD HH24:MI'));

-- Pedido concluído.
INSERT INTO pedido (socio, numero_seq, veiculo, data_pedido, problema,
                    estado, turno_mecanico, turno_veiculo, turno_desde,
                    assist_desde, assist_ate)
     VALUES (123456789, 1, 'AA-12-34',
             TO_DATE('2026-03-10 09:15', 'YYYY-MM-DD HH24:MI'),
             'Pneu furado', 'ASSISTÊNCIA CONCLUÍDA',
             234567890, 'AB-12-CD',
             TO_DATE('2026-03-10 08:00', 'YYYY-MM-DD HH24:MI'),
             TO_DATE('2026-03-10 09:40', 'YYYY-MM-DD HH24:MI'),
             TO_DATE('2026-03-10 10:30', 'YYYY-MM-DD HH24:MI'));

-- Pedido com assistência em curso.
INSERT INTO pedido (socio, numero_seq, veiculo, data_pedido, problema,
                    estado, turno_mecanico, turno_veiculo, turno_desde,
                    assist_desde, assist_ate)
     VALUES (123456789, 2, 'AA-12-34',
             TO_DATE('2026-03-11 10:00', 'YYYY-MM-DD HH24:MI'),
             'Bateria descarregada', 'ASSISTÊNCIA EM CURSO',
             234567890, 'AB-12-CD',
             TO_DATE('2026-03-11 08:00', 'YYYY-MM-DD HH24:MI'),
             TO_DATE('2026-03-11 10:20', 'YYYY-MM-DD HH24:MI'), NULL);

-- Pedido feito pelo sócio que também é mecânico.
INSERT INTO pedido (socio, numero_seq, veiculo, data_pedido, problema,
                    estado, turno_mecanico, turno_veiculo, turno_desde,
                    assist_desde, assist_ate)
     VALUES (234567890, 1, '12-34-BB',
             TO_DATE('2026-03-10 12:00', 'YYYY-MM-DD HH24:MI'),
             'Corrente partida', 'ASSISTÊNCIA CONCLUÍDA',
             345678901, 'BC-45-DE',
             TO_DATE('2026-03-10 08:00', 'YYYY-MM-DD HH24:MI'),
             TO_DATE('2026-03-10 12:30', 'YYYY-MM-DD HH24:MI'),
             TO_DATE('2026-03-10 13:45', 'YYYY-MM-DD HH24:MI'));

-- Pedido ainda sem assistência atribuída.
INSERT INTO pedido (socio, numero_seq, veiculo, data_pedido, problema,
                    estado, turno_mecanico, turno_veiculo, turno_desde,
                    assist_desde, assist_ate)
     VALUES (456789012, 1, '56-CD-78',
             TO_DATE('2026-03-10 11:00', 'YYYY-MM-DD HH24:MI'),
             'Avaria no motor', 'ASSISTÊNCIA PEDIDA',
             NULL, NULL, NULL, NULL, NULL);

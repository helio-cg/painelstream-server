import os
import re
from unidecode import unidecode

def remover_caracteres(texto):
    # Converte caracteres acentuados para ASCII
    texto = unidecode(texto)

    # Remove caracteres especiais indesejados, mantendo letras, números, espaços, hífens e underscores
    texto = re.sub(r"[^a-zA-Z0-9\s\-_.]", "", texto)

    # Substitui múltiplos espaços por um único espaço e remove espaços no início e fim
    texto = re.sub(r"\s+", " ", texto).strip()

    return texto
# Contribuindo para o usb-driver

Obrigado por considerar contribuir! 🎉

## Como Contribuir

### Reportando Bugs

1. Verifique se o bug já não foi reportado nas [Issues](../../issues)
2. Se não, abra uma nova issue com:
   - Descrição clara do problema
   - Passos para reproduzir
   - Comportamento esperado vs. atual
   - Versão do WSL e Windows

### Sugerindo Melhorias

Abra uma issue com a tag `enhancement` descrevendo:
- O problema que a melhoria resolve
- Como você imagina a solução
- Alternativas consideradas

### Pull Requests

1. Fork o repositório
2. Crie uma branch descritiva:
   ```bash
   git checkout -b feature/minha-funcionalidade
   # ou
   git checkout -b fix/correcao-bug
   ```
3. Faça suas alterações seguindo o estilo do código existente
4. Teste suas mudanças
5. Commit com mensagens claras:
   ```bash
   git commit -m "feat: adiciona suporte a exFAT"
   git commit -m "fix: corrige detecção de dispositivo"
   ```
6. Push e abra o PR

## Estilo de Código

- Use **bash** com `set -e` para fail-fast
- Indentação com **4 espaços**
- Funções com nomes descritivos em `snake_case`
- Comentários em português
- Variáveis em UPPERCASE para globais, lowercase para locais

## Estrutura de Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` nova funcionalidade
- `fix:` correção de bug
- `docs:` documentação
- `refactor:` refatoração
- `test:` testes
- `chore:` manutenção

## Testes

Antes de enviar um PR, teste:

```bash
# Verificar instalação
./scripts/install.sh --check

# Testar modo simulação
usb-driver --simulate up
usb-driver --simulate down

# Testar com pendrive real (se disponível)
usb-driver up
usb-driver status
usb-driver down
```

## Dúvidas?

Abra uma issue com a tag `question`.

---

Obrigado por contribuir! 🚀

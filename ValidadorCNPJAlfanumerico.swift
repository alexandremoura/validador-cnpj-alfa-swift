import Foundation


class ValidadorCNPJAlfanumerico {
    
    // Constantes
    private static let tamanhoCNPJSemDV = 12
    private static let valorBase: Int = 48 // '0' em ASCII = 48
    private static let cnpjZerado = "00000000000000"
    
    // Pesos para cálculo dos dígitos verificadores
    private static let pesosDV: [Int] = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    
    // Expressões regulares
    private static let regexCaracteresNaoPermitidos: NSRegularExpression = {
        do {
            // Ajustei a regex para permitir letras e números
            // A regex original parece bloquear caracteres não permitidos
            // Vou criar uma que valida apenas caracteres alfanuméricos
            return try NSRegularExpression(pattern: "^[A-Za-z0-9]+$", options: [])
        } catch {
            fatalError("Erro ao criar regex: \(error)")
        }
    }()
    
    private static let regexCNPJSemDV: NSRegularExpression = {
        do {
            // Valida 12 caracteres alfanuméricos
            return try NSRegularExpression(pattern: "^[A-Za-z0-9]{12}$", options: [])
        } catch {
            fatalError("Erro ao criar regex: \(error)")
        }
    }()
    
    // Remove máscara do CNPJ (mantém apenas letras e números)
    static func removeMascaraCNPJ(_ cnpj: String) -> String {
        return cnpj.uppercased().filter { $0.isLetter || $0.isNumber }
    }
    
    // Calcula os dígitos verificadores
    static func calculaDV(cnpj: String) throws -> String {
        // Verifica se não contém caracteres não permitidos
        let range = NSRange(location: 0, length: cnpj.utf16.count)
        let temCaracteresValidos = regexCaracteresNaoPermitidos.numberOfMatches(in: cnpj, options: [], range: range) > 0
        
        if temCaracteresValidos {
            let cnpjSemMascara = removeMascaraCNPJ(cnpj)
            
            // Verifica se tem o formato correto sem DV
            let rangeSemMascara = NSRange(location: 0, length: cnpjSemMascara.utf16.count)
            let formatoCorreto = regexCNPJSemDV.numberOfMatches(in: cnpjSemMascara, options: [], range: rangeSemMascara) > 0
            
            if formatoCorreto && cnpjSemMascara != cnpjZerado.substring(to: tamanhoCNPJSemDV) {
                var somatorioDV1 = 0
                var somatorioDV2 = 0
                
                // Calcula os somatórios
                for i in 0..<tamanhoCNPJSemDV {
                    let caractere = cnpjSemMascara[cnpjSemMascara.index(cnpjSemMascara.startIndex, offsetBy: i)]
                    
                    // Obtém o valor ASCII do caractere e subtrai 48 (valor base)
                    // Isso converte '0'-'9' para 0-9 e 'A'-'Z' para seus valores correspondentes
                    let asciiDigito = Int(caractere.asciiValue ?? 0) - valorBase
                    
                    // Verifica se o caractere é válido (0-9 ou A-Z)
                    guard asciiDigito >= 0 && asciiDigito <= 42 else {
                        throw NSError(domain: "CNPJInvalido", code: 1, userInfo: [NSLocalizedDescriptionKey: "Caractere inválido no CNPJ"])
                    }
                    
                    // Calcula somatório para DV1 (usa pesos de 1 a 12)
                    somatorioDV1 += asciiDigito * pesosDV[i + 1]
                    
                    // Calcula somatório para DV2 (usa pesos de 0 a 11)
                    somatorioDV2 += asciiDigito * pesosDV[i]
                }
                
                // Calcula DV1
                let dv1 = somatorioDV1 % 11 < 2 ? 0 : 11 - (somatorioDV1 % 11)
                
                // Adiciona contribuição do DV1 ao somatório do DV2
                somatorioDV2 += dv1 * pesosDV[tamanhoCNPJSemDV]
                
                // Calcula DV2
                let dv2 = somatorioDV2 % 11 < 2 ? 0 : 11 - (somatorioDV2 % 11)
                
                return "\(dv1)\(dv2)"
            }
        }
        
        throw NSError(domain: "CNPJInvalido", code: 2, userInfo: [NSLocalizedDescriptionKey: "Não é possível calcular o DV pois o CNPJ fornecido é inválido"])
    }
    
    // Valida o CNPJ completo (12 caracteres + 2 dígitos)
    static func validarCNPJ(_ cnpj: String) -> Bool {
        let cnpjLimpo = removeMascaraCNPJ(cnpj)
        
        // Verifica se tem 14 caracteres
        guard cnpjLimpo.count == 14 else {
            return false
        }
        
        do {
            // Pega os primeiros 12 caracteres para calcular o DV
            let base = String(cnpjLimpo.prefix(tamanhoCNPJSemDV))
            let dvCalculado = try calculaDV(cnpj: base)
            
            // Pega os últimos 2 caracteres (dígitos informados)
            let dvInformado = String(cnpjLimpo.suffix(2))
            
            return dvCalculado == dvInformado
        } catch {
            return false
        }
    }
    
    // Método auxiliar para obter valor de caractere (0-9, A-Z)
    private static func valorCaractere(_ caractere: Character) -> Int? {
        guard let asciiValue = caractere.asciiValue else { return nil }
        
        let valor = Int(asciiValue) - valorBase
        
        // Verifica se está no intervalo válido (0-35)
        // 0-9: números, 17-42: letras A-Z (quando uppercase)
        if valor >= 0 && valor <= 35 {
            return valor
        }
        
        return nil
    }
}

// Extensão para String (similar ao substring do TypeScript)
extension String {
    func substring(to index: Int) -> String {
        guard index <= self.count else { return self }
        let endIndex = self.index(self.startIndex, offsetBy: index)
        return String(self[..<endIndex])
    }
}



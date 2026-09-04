//
//  HijaiyahLetterAppEnum.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 03/09/26.
//

import Foundation
import AppIntents

enum HijaiyahLetterAppEnum: String, AppEnum {
    case alif = "alif"
    case ba = "ba"
    case ta = "ta"
    case tsa = "tsa"
    case jim = "jim"
    case ha = "ha"
    case kha = "kha"
    case dal = "dal"
    case dzal = "dzal"
    case ra = "ra"
    case zai = "zai"
    case sin = "sin"
    case syin = "syin"
    case shad = "shad"
    case dhad = "dhad"
    case tha = "tha"
    case zha = "zha"
    case ain = "ain"
    case ghain = "ghain"
    case fa = "fa"
    case qaf = "qaf"
    case kaf = "kaf"
    case lam = "lam"
    case mim = "mim"
    case nun = "nun"
    case haa = "haa"
    case waw = "waw"
    case ya = "ya"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Huruf Hijaiyah"
    
    static var caseDisplayRepresentations: [HijaiyahLetterAppEnum : DisplayRepresentation] = [
        .alif: DisplayRepresentation(title: "Alif (أ)"),
        .ba: DisplayRepresentation(title: "Ba (ب)"),
        .ta: DisplayRepresentation(title: "Ta (ت)"),
        .tsa: DisplayRepresentation(title: "Tsa (ث)"),
        .jim: DisplayRepresentation(title: "Jim (ج)"),
        .ha: DisplayRepresentation(title: "Ha (ح)"),
        .kha: DisplayRepresentation(title: "Kha (خ)"),
        .dal: DisplayRepresentation(title: "Dal (د)"),
        .dzal: DisplayRepresentation(title: "Dzal (ذ)"),
        .ra: DisplayRepresentation(title: "Ra (ر)"),
        .zai: DisplayRepresentation(title: "Zai (ز)"),
        .sin: DisplayRepresentation(title: "Sin (س)"),
        .syin: DisplayRepresentation(title: "Syin (ش)"),
        .shad: DisplayRepresentation(title: "Shad (ص)"),
        .dhad: DisplayRepresentation(title: "Dhad (ض)"),
        .tha: DisplayRepresentation(title: "Tha (ط)"),
        .zha: DisplayRepresentation(title: "Zha (ظ)"),
        .ain: DisplayRepresentation(title: "Ain (ع)"),
        .ghain: DisplayRepresentation(title: "Ghain (غ)"),
        .fa: DisplayRepresentation(title: "Fa (ف)"),
        .qaf: DisplayRepresentation(title: "Qaf (ق)"),
        .kaf: DisplayRepresentation(title: "Kaf (ك)"),
        .lam: DisplayRepresentation(title: "Lam (ل)"),
        .mim: DisplayRepresentation(title: "Mim (م)"),
        .nun: DisplayRepresentation(title: "Nun (ن)"),
        .haa: DisplayRepresentation(title: "Haa (هـ)"),
        .waw: DisplayRepresentation(title: "Waw (و)"),
        .ya: DisplayRepresentation(title: "Ya (ي)")
    ]
    
    var arabic: String {
        switch self {
        case .alif: return "ا"
        case .ba: return "ب"
        case .ta: return "ت"
        case .tsa: return "ث"
        case .jim: return "ج"
        case .ha: return "ح"
        case .kha: return "خ"
        case .dal: return "د"
        case .dzal: return "ذ"
        case .ra: return "ر"
        case .zai: return "ز"
        case .sin: return "س"
        case .syin: return "ش"
        case .shad: return "ص"
        case .dhad: return "ض"
        case .tha: return "ط"
        case .zha: return "ظ"
        case .ain: return "ع"
        case .ghain: return "غ"
        case .fa: return "ف"
        case .qaf: return "ق"
        case .kaf: return "ك"
        case .lam: return "ل"
        case .mim: return "م"
        case .nun: return "ن"
        case .haa: return "هـ"
        case .waw: return "و"
        case .ya: return "ي"
        }
    }
}

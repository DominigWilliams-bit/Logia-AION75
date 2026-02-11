import jsPDF from 'jspdf';
import defaultLogoImg from '@/assets/logo-institucional.png';
import { supabase } from '@/integrations/supabase/client-unsafe';

interface SignatureInfo {
  name: string;
  cargo: string;
  signatureUrl?: string | null;
}

interface ReceiptData {
  receiptNumber: string;
  memberName: string;
  memberDegree?: string;
  concept: string;
  totalAmount: number;
  amountPaid: number;
  paymentDate: string;
  institutionName: string;
  logoUrl?: string | null;
  remainingBalance?: number;
  details?: string[];
  treasurer?: SignatureInfo;
  venerableMaestro?: SignatureInfo;
}

async function loadImage(url: string): Promise<HTMLImageElement | null> {
  return new Promise((resolve) => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => resolve(img);
    img.onerror = () => resolve(null);
    img.src = url;
  });
}

function numberToWords(n: number): string {
  const units = ['', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve'];
  const teens = ['diez', 'once', 'doce', 'trece', 'catorce', 'quince', 'dieciséis', 'diecisiete', 'dieciocho', 'diecinueve'];
  const tens = ['', '', 'veinte', 'treinta', 'cuarenta', 'cincuenta', 'sesenta', 'setenta', 'ochenta', 'noventa'];
  const hundreds = ['', 'ciento', 'doscientos', 'trescientos', 'cuatrocientos', 'quinientos', 'seiscientos', 'setecientos', 'ochocientos', 'novecientos'];

  if (n === 0) return 'cero';
  if (n === 100) return 'cien';

  let result = '';
  const intPart = Math.floor(n);
  const decPart = Math.round((n - intPart) * 100);

  if (intPart >= 1000) {
    const thousands = Math.floor(intPart / 1000);
    if (thousands === 1) result += 'mil ';
    else result += numberToWords(thousands) + ' mil ';
  }

  const remainder = intPart % 1000;
  if (remainder >= 100) {
    result += hundreds[Math.floor(remainder / 100)] + ' ';
  }

  const lastTwo = remainder % 100;
  if (lastTwo >= 10 && lastTwo <= 19) {
    result += teens[lastTwo - 10];
  } else {
    if (lastTwo >= 20) {
      result += tens[Math.floor(lastTwo / 10)];
      if (lastTwo % 10 !== 0) {
        result += ' y ' + units[lastTwo % 10];
      }
    } else if (lastTwo > 0) {
      result += units[lastTwo];
    }
  }

  result = result.trim();
  if (decPart > 0) {
    result += ` con ${decPart}/100`;
  } else {
    result += ' con 00/100';
  }

  return result.charAt(0).toUpperCase() + result.slice(1);
}

function formatDate(dateStr: string): string {
  try {
    const d = new Date(dateStr + 'T12:00:00');
    return d.toLocaleDateString('es-EC', { day: '2-digit', month: 'long', year: 'numeric' });
  } catch {
    return dateStr;
  }
}

/**
 * Generate a clean, formal payment receipt (portrait A4).
 * Structure:
 *   1. Logo (top-left, proportional)
 *   2. Institution name (centered)
 *   3. Title centered (RECIBO DE PAGO)
 *   4. Date right-aligned, Receipt number right-aligned
 *   5. Body paragraph with member, concept, amounts
 *   6. Signatures at bottom
 */
export async function generatePaymentReceipt(data: ReceiptData): Promise<jsPDF> {
  const doc = new jsPDF({ format: 'a4', orientation: 'portrait' });
  const pageWidth = 210;
  const ml = 25;
  const mr = 25;
  const cw = pageWidth - ml - mr;
  const fontSize = 10;

  // ─── LOGO ─────────────────────────────────────────────
  let y = 20;

  const logoSrc = data.logoUrl || defaultLogoImg;
  let logoImg = await loadImage(logoSrc);
  if (!logoImg && data.logoUrl) {
    logoImg = await loadImage(defaultLogoImg);
  }
  if (logoImg) {
    const maxW = 22;
    const maxH = 22;
    const r = Math.min(maxW / logoImg.width, maxH / logoImg.height);
    doc.addImage(logoImg, 'PNG', ml, y, logoImg.width * r, logoImg.height * r);
  }

  // ─── INSTITUTION NAME (centered) ──────────────────────
  y += 8;
  doc.setFontSize(fontSize);
  doc.setFont('helvetica', 'normal');
  doc.text(data.institutionName, pageWidth / 2, y, { align: 'center' });

  // ─── TITLE (centered, bold, slightly larger) ──────────
  y += 10;
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.text('RECIBO DE PAGO', pageWidth / 2, y, { align: 'center' });

  // ─── DATE & RECEIPT NUMBER (right-aligned) ────────────
  y += 12;
  doc.setFontSize(fontSize);
  doc.setFont('helvetica', 'normal');
  doc.text(`Fecha: ${formatDate(data.paymentDate)}`, pageWidth - mr, y, { align: 'right' });
  y += 5;
  doc.text(`Número: ${data.receiptNumber}`, pageWidth - mr, y, { align: 'right' });

  y += 10;

  // ─── BODY PARAGRAPH ───────────────────────────────────
  doc.setFontSize(fontSize);
  doc.setFont('helvetica', 'normal');

  const degreeLabels: Record<string, string> = {
    aprendiz: 'Aprendiz',
    companero: 'Compañero',
    maestro: 'Maestro',
  };
  const degreeText = data.memberDegree ? `, grado ${degreeLabels[data.memberDegree] || data.memberDegree}` : '';

  const amountWords = numberToWords(data.amountPaid);

  let bodyText = `Recibí de ${data.memberName}${degreeText}, la suma de $${data.amountPaid.toFixed(2)} (${amountWords} dólares) por el concepto de ${data.concept}.`;

  if (data.totalAmount > 0 && data.totalAmount !== data.amountPaid) {
    bodyText += ` El valor total de la cuota es de $${data.totalAmount.toFixed(2)}.`;
  }

  if (data.remainingBalance !== undefined && data.remainingBalance > 0) {
    bodyText += ` Saldo pendiente: $${data.remainingBalance.toFixed(2)}.`;
  }

  const bodyLines = doc.splitTextToSize(bodyText, cw);
  doc.text(bodyLines, ml, y);
  y += bodyLines.length * 5 + 4;

  // ─── ADDITIONAL DETAILS ───────────────────────────────
  if (data.details && data.details.length > 0) {
    y += 2;
    for (const detail of data.details) {
      doc.text(`• ${detail}`, ml + 5, y);
      y += 5;
    }
  }

  // ─── CONFORMITY TEXT ──────────────────────────────────
  y += 12;
  doc.setFontSize(fontSize);
  doc.setFont('helvetica', 'normal');
  doc.text('Recibí de conformidad.', ml, y);

  // ─── SIGNATURES ───────────────────────────────────────
  const sigY = y + 40;
  const sigLineW = 60;
  const leftX = ml + cw * 0.25;
  const rightX = ml + cw * 0.75;

  // Treasurer signature image (left)
  if (data.treasurer?.signatureUrl) {
    const sigImg = await loadImage(data.treasurer.signatureUrl);
    if (sigImg) {
      const r = Math.min(55 / sigImg.width, 28 / sigImg.height);
      doc.addImage(sigImg, 'PNG', leftX - (sigImg.width * r) / 2, sigY - 28, sigImg.width * r, sigImg.height * r);
    }
  }

  // VM signature image (right)
  if (data.venerableMaestro?.signatureUrl) {
    const sigImg = await loadImage(data.venerableMaestro.signatureUrl);
    if (sigImg) {
      const r = Math.min(55 / sigImg.width, 28 / sigImg.height);
      doc.addImage(sigImg, 'PNG', rightX - (sigImg.width * r) / 2, sigY - 28, sigImg.width * r, sigImg.height * r);
    }
  }

  // Signature lines
  doc.setLineWidth(0.3);
  doc.setDrawColor(60, 60, 60);

  // Left: Tesorero
  doc.line(leftX - sigLineW / 2, sigY, leftX + sigLineW / 2, sigY);
  doc.setFontSize(fontSize);
  doc.setFont('helvetica', 'normal');
  doc.text(data.treasurer?.name || 'Tesorero', leftX, sigY + 5, { align: 'center' });
  doc.setFont('helvetica', 'bold');
  doc.text(data.treasurer?.cargo || 'Tesorero', leftX, sigY + 10, { align: 'center' });

  // Right: Venerable Maestro
  doc.line(rightX - sigLineW / 2, sigY, rightX + sigLineW / 2, sigY);
  doc.setFont('helvetica', 'normal');
  doc.text(data.venerableMaestro?.name || 'Venerable Maestro', rightX, sigY + 5, { align: 'center' });
  doc.setFont('helvetica', 'bold');
  doc.text(data.venerableMaestro?.cargo || 'Venerable Maestro', rightX, sigY + 10, { align: 'center' });

  // ─── FOOTER ───────────────────────────────────────────
  const pageHeight = 297;
  doc.setFontSize(7);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(130, 130, 130);
  doc.text(
    'Este comprobante de pago es un documento válido emitido por la tesorería de la institución.',
    pageWidth / 2,
    pageHeight - 15,
    { align: 'center' }
  );
  doc.setTextColor(0, 0, 0);

  return doc;
}

/** Get next sequential receipt number from database */
export async function getNextReceiptNumber(module: 'treasury' | 'extraordinary' | 'degree'): Promise<string> {
  try {
    const { data, error } = await (supabase as any).rpc('get_next_receipt_number', { p_module: module });
    if (error) throw error;
    return data as string;
  } catch (err) {
    console.error('Error getting receipt number:', err);
    const now = new Date();
    const prefix = module === 'treasury' ? 'TSR' : module === 'extraordinary' ? 'EXT' : 'GRD';
    return `${prefix}${now.getTime().toString().slice(-7)}`;
  }
}

export function downloadReceipt(doc: jsPDF, memberName: string) {
  const safeName = memberName.replace(/[^a-zA-Z0-9]/g, '_').slice(0, 20);
  doc.save(`Recibo_${safeName}_${new Date().toISOString().slice(0, 10)}.pdf`);
}

export function getReceiptWhatsAppMessage(
  memberName: string,
  concept: string,
  amountPaid: number,
  remaining?: number
): string {
  const firstName = memberName.split(' ')[0];
  let msg = `Estimado H∴ ${firstName},\n\n` +
    `Se ha registrado su pago correspondiente a: ${concept}\n` +
    `💰 Monto pagado: $${amountPaid.toFixed(2)}\n`;

  if (remaining && remaining > 0) {
    msg += `⚠️ Saldo pendiente: $${remaining.toFixed(2)}\n`;
  }

  msg += `\nFraternalmente,\nTesorería`;
  return msg;
}

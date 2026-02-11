import { useEffect, useState, useMemo, forwardRef } from 'react';
import { supabase } from '@/integrations/supabase/client-unsafe';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Plus, Pencil, Trash2, MessageCircle, Search, ChevronLeft, ChevronRight } from 'lucide-react';
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from '@/components/ui/table';
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
} from '@/components/ui/dialog';
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import {
  Tooltip, TooltipContent, TooltipProvider, TooltipTrigger,
} from '@/components/ui/tooltip';
import MemberForm from '@/components/forms/MemberForm';
import { useToast } from '@/hooks/use-toast';
import { removeCachedMember } from '@/hooks/useDataCache';
import { sendBirthdayWhatsApp } from '@/hooks/useBirthdayMembers';
import { isBirthdayToday, formatDateForDisplay } from '@/lib/dateUtils';
import { Badge } from '@/components/ui/badge';

interface Member {
  id: string;
  full_name: string;
  degree: string | null;
  phone: string | null;
  email: string | null;
  status: string | null;
  treasury_amount: number | null;
  is_treasurer: boolean | null;
  cedula: string | null;
  address: string | null;
  join_date: string | null;
  birth_date: string | null;
  created_at: string;
  cargo_logial: string | null;
  emergency_contact_name: string | null;
  emergency_contact_phone: string | null;
}

const STATUS_LABELS: Record<string, string> = {
  activo: 'Activo',
  inactivo: 'Inactivo',
};

const GRADE_LABELS: Record<string, string> = {
  aprendiz: 'Aprendiz',
  companero: 'Companero',
  maestro: 'Maestro',
};

const CARGO_LABELS: Record<string, string> = {
  venerable_maestro: 'Venerable Maestro',
  past_venerable_maestro: 'Past Venerable Maestro',
  primer_vigilante: 'Primer Vigilante',
  segundo_vigilante: 'Segundo Vigilante',
  tesorero: 'Tesorero',
};

const PAGE_SIZE = 25;

const Members = forwardRef<HTMLDivElement>(function Members(_props, ref) {
  const [members, setMembers] = useState<Member[]>([]);
  const [loading, setLoading] = useState(true);
  const [showDialog, setShowDialog] = useState(false);
  const [selectedMember, setSelectedMember] = useState<Member | undefined>();
  const [memberToDelete, setMemberToDelete] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const { toast } = useToast();

  const filteredMembers = useMemo(() => {
    if (!searchTerm.trim()) return members;
    const term = searchTerm.toLowerCase();
    return members.filter((m) =>
      m.full_name.toLowerCase().includes(term) ||
      (m.degree && (GRADE_LABELS[m.degree] || m.degree).toLowerCase().includes(term))
    );
  }, [members, searchTerm]);

  const totalPages = Math.max(1, Math.ceil(filteredMembers.length / PAGE_SIZE));
  const paginatedMembers = useMemo(() => {
    const start = (currentPage - 1) * PAGE_SIZE;
    return filteredMembers.slice(start, start + PAGE_SIZE);
  }, [filteredMembers, currentPage]);

  useEffect(() => { setCurrentPage(1); }, [searchTerm]);

  useEffect(() => {
    loadMembers();
  }, []);

  const loadMembers = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from('members')
      .select('*')
      .order('full_name');

    if (!error && data) {
      setMembers(data as Member[]);
    }
    setLoading(false);
  };

  const handleEdit = (member: Member) => {
    setSelectedMember(member);
    setShowDialog(true);
  };

  const handleNew = () => {
    setSelectedMember(undefined);
    setShowDialog(true);
  };

  const handleDelete = async () => {
    if (!memberToDelete) return;
    try {
      const { error } = await supabase.from('members').delete().eq('id', memberToDelete);
      if (error) throw error;
      toast({ title: 'Miembro eliminado correctamente' });
      removeCachedMember(memberToDelete);
      loadMembers();
    } catch (error: any) {
      toast({ title: 'Error', description: error.message || 'No se pudo eliminar el miembro', variant: 'destructive' });
    } finally {
      setMemberToDelete(null);
    }
  };

  return (
    <div ref={ref} className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-3xl font-bold">Gestion de Miembros</h1>
          <p className="text-muted-foreground mt-1">Administre el registro de miembros de la logia</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="relative w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input placeholder="Buscar por nombre o grado..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} className="pl-9" />
          </div>
          <Button onClick={handleNew}>
            <Plus className="mr-2 h-4 w-4" />
            Nuevo Miembro
          </Button>
        </div>
      </div>

      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="min-w-[180px] text-sm">Nombre Completo</TableHead>
              <TableHead className="w-[100px] text-sm">Grado</TableHead>
              <TableHead className="w-[150px] text-sm">Cargo Logial</TableHead>
              <TableHead className="w-[100px] text-sm">Cedula</TableHead>
              
              <TableHead className="w-[120px] text-sm">Fecha Ingreso</TableHead>
              <TableHead className="w-[80px] text-sm">Estado</TableHead>
              <TableHead className="w-[120px] text-right text-sm">Acciones</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-8">Cargando...</TableCell>
              </TableRow>
            ) : filteredMembers.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-8 text-muted-foreground">
                  {searchTerm ? 'No se encontraron resultados' : 'No hay miembros registrados'}
                </TableCell>
              </TableRow>
            ) : (
              paginatedMembers.map((member) => {
                const memberIsBirthday = isBirthdayToday(member.birth_date);
                const hasPhone = !!member.phone;
                
                return (
                  <TableRow key={member.id} className={memberIsBirthday ? 'bg-accent/10' : ''}>
                    <TableCell className="font-medium text-sm">
                      <div className="flex items-center gap-2">
                        {member.full_name}
                      </div>
                    </TableCell>
                    <TableCell className="text-sm">
                      {GRADE_LABELS[member.degree || ''] || member.degree || 'N/A'}
                    </TableCell>
                    <TableCell className="text-sm">
                      {member.cargo_logial ? (
                        <Badge variant="outline" className="text-xs">
                          {CARGO_LABELS[member.cargo_logial] || member.cargo_logial}
                        </Badge>
                      ) : '-'}
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {member.cedula || '-'}
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {member.join_date ? formatDateForDisplay(member.join_date) : '-'}
                    </TableCell>
                    <TableCell>
                      <span className={`text-sm ${member.status === 'activo' ? 'font-bold' : 'text-muted-foreground'}`}>
                        {STATUS_LABELS[member.status || 'activo'] || 'Activo'}
                      </span>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex gap-1 justify-end">
                        <Button variant="ghost" size="sm" onClick={() => handleEdit(member)}>
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="sm" onClick={() => setMemberToDelete(member.id)}>
                          <Trash2 className="h-4 w-4" />
                        </Button>
                        {memberIsBirthday && hasPhone && (
                          <TooltipProvider>
                            <Tooltip>
                              <TooltipTrigger asChild>
                                <Button variant="default" size="sm" className="bg-success hover:bg-success/80 text-success-foreground"
                                  onClick={() => sendBirthdayWhatsApp(member)}>
                                  <MessageCircle className="h-4 w-4" />
                                </Button>
                              </TooltipTrigger>
                              <TooltipContent><p>Enviar felicitacion por WhatsApp</p></TooltipContent>
                            </Tooltip>
                          </TooltipProvider>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">
            Mostrando {((currentPage - 1) * PAGE_SIZE) + 1}–{Math.min(currentPage * PAGE_SIZE, filteredMembers.length)} de {filteredMembers.length}
          </p>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" disabled={currentPage <= 1} onClick={() => setCurrentPage(p => p - 1)}>
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <span className="text-sm">Página {currentPage} de {totalPages}</span>
            <Button variant="outline" size="sm" disabled={currentPage >= totalPages} onClick={() => setCurrentPage(p => p + 1)}>
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{selectedMember ? 'Editar Miembro' : 'Nuevo Miembro'}</DialogTitle>
          </DialogHeader>
          <MemberForm
            member={selectedMember}
            onSuccess={() => { setShowDialog(false); loadMembers(); }}
            onCancel={() => setShowDialog(false)}
          />
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!memberToDelete} onOpenChange={() => setMemberToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Esta seguro?</AlertDialogTitle>
            <AlertDialogDescription>
              Esta accion no se puede deshacer. Se eliminara el miembro y todos sus registros asociados.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete}>Eliminar</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
});

export default Members;

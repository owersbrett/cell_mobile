export function ProgressBar({ percent, label }: { percent: number; label?: string }) {
  const p = Math.max(0, Math.min(100, percent));
  return (
    <div>
      <div className="bar" role="progressbar" aria-valuenow={p} aria-valuemin={0} aria-valuemax={100}>
        <span style={{ width: `${p}%` }} />
      </div>
      {label !== undefined && <div className="bar-label">{label}</div>}
    </div>
  );
}

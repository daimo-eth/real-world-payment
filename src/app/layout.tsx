import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Real World Payment — Daimo",
  description:
    "Send USD to real people via Venmo, CashApp, Zelle, and more. Powered by Daimo + Peer Protocol.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

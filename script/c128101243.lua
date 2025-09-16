--Holophantasy – Continuous Spell (Custom)
local s,id=GetID()
function s.initial_effect(c)
  --① 이 카드명의 카드는 1턴에 1장만 발동 가능 + 발동시 처리
  local e0=Effect.CreateEffect(c)
  e0:SetDescription(aux.Stringid(id,0))
  -- (카테고리는 굳이 안 붙임: 발동 처리에서 '배치'만 하므로 검색/회수 카테고리 아님)
  e0:SetType(EFFECT_TYPE_ACTIVATE)
  e0:SetCode(EVENT_FREE_CHAIN)
  -- ★ OATH 형식으로 동일명 발동 1턴 1회 (Pressured Planet과 동일)
  e0:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
  e0:SetOperation(s.actop)
  c:RegisterEffect(e0)

  --② 1턴에 1번: 필드존 카드 1장 GY → 덱에서 "홀로판타지" 몬스터 1장 서치
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id,1))
  e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_SZONE)
  e1:SetCountLimit(1,{id,1})  -- 카드명 하드 OPT
  e1:SetTarget(s.thtg)
  e1:SetOperation(s.thop)
  c:RegisterEffect(e1)
end
s.listed_series={0xc44}

-- ① 발동시: 덱/묘지의 "홀로판타지" 필드 마법 1장을 '배치'할 수 있다
function s.fspellfilter(c)
  return c:IsSetCard(0xc44) and c:IsType(TYPE_FIELD)
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
  local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.fspellfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
  if #g==0 then return end
  if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then  -- "배치할 필드 마법을 고르겠습니까?"
    Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,3)) -- "필드 마법을 선택"
    local tc=g:Select(tp,1,1,nil):GetFirst()
    if tc and not tc:IsForbidden() then
      -- 기존 필드존 처리(룰에 따름) 후 앞면으로 '배치'
      Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
    end
  end
end

-- ② 1턴 1번: 필드존 1장 GY → 덱에서 "홀로판타지" 몬스터 1장 서치
function s.fztgfilter(c) return c:IsLocation(LOCATION_FZONE) and c:IsAbleToGrave() end
function s.thfilter(c)   return c:IsSetCard(0xc44) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand() end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chkc then return chkc:IsLocation(LOCATION_FZONE) and s.fztgfilter(chkc) end
  if chk==0 then
    return Duel.IsExistingTarget(s.fztgfilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
       and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
  end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
  local g=Duel.SelectTarget(tp,s.fztgfilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,1,nil)
  Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
  local tc=Duel.GetFirstTarget()
  if not (tc and tc:IsRelateToEffect(e)) then return end
  if Duel.SendtoGrave(tc,REASON_EFFECT)>0 then
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
      Duel.SendtoHand(g,nil,REASON_EFFECT)
      Duel.ConfirmCards(1-tp,g)
    end
  end
end

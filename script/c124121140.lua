-- 데몬의 쇄진 (일반 마법 버전 - 엑스트라 덱 제약 추가)
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 덱 / 묘지 / 제외 상태에서 "데몬" 카드 1장과, 서로의 카드명이 기재된 카드 1장을 패에 넣는다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ②: 상대가 발동한 카드의 효과 발동에 체인하여 자신이 "데몬" 카드의 효과를 발동했을 때, 무효화
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.discon)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)
end
s.listed_series={0x45} -- 데몬

-- ==========================================================
-- [①번 효과: 서치 로직 + 디메리트]
-- ==========================================================
function s.thfilter(c) 
	return (c:IsLocation(LOCATION_DECK+LOCATION_GRAVE) or c:IsFaceup()) and c:IsAbleToHand() 
end

function s.rescon(sg,e,tp,mg)
	if sg:GetCount()~=2 then return false end
	local c1=sg:GetFirst() local c2=sg:GetNext()
	local function check(a,b) return a:IsSetCard(0x45) and (a:ListsCode(b:GetCode()) or b:ListsCode(a:GetCode())) end
	return check(c1,c2) or check(c2,c1)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	if chk==0 then return aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,0) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	local sg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_ATOHAND)
	if sg and sg:GetCount()==2 then
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
	
	-- 이 효과의 발동 후, 턴 종료시까지 자신은 "데몬" 몬스터밖에 엑스트라 덱에서 특수 소환할 수 없다.
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,2)) -- 클라이언트 힌트용 (cdb 텍스트 2번: "데몬 몬스터밖에 엑스트라 덱에서 특수 소환할 수 없다")
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c) return c:IsLocation(LOCATION_EXTRA) and not c:IsSetCard(0x45) end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-- ==========================================================
-- [② 무효화 함수]
-- ==========================================================
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	if ep~=tp or ev<2 or Duel.HasFlagEffect(tp,id+1) then return false end
	local rc = re:GetHandler()
	if not rc or not rc:IsSetCard(0x45) then return false end
	local ch = ev - 1
	if not Duel.IsChainDisablable(ch) then return false end
	local prev_ctrl = Duel.GetChainInfo(ch, CHAININFO_TRIGGERING_CONTROLER)
	return prev_ctrl == 1-tp
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,1)) then return end
	Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE+PHASE_END,0,1)
	Duel.Hint(HINT_CARD,0,id)
	if Duel.NegateEffect(ev-1) then
		Duel.BreakEffect()
		Duel.Remove(c,POS_FACEUP,REASON_EFFECT)
	end
end
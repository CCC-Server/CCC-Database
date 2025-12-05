local s,id=GetID()
function s.initial_effect(c)
	---------------------------------------
	-- ① 이 카드 발동 (덱 서치 효과 포함)
	---------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	---------------------------------------
	-- ② 상대 효과 발동 시 → 엑시즈 진화
	---------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.xyzcon)
	e2:SetTarget(s.xyztg)
	e2:SetOperation(s.xyzop)
	c:RegisterEffect(e2)

	---------------------------------------
	-- ③ 몬스터 NS/SS → 상대 덱 위 3장 확인/정렬
	---------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DECKDES)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.top3tg)
	e3:SetOperation(s.top3op)
	c:RegisterEffect(e3)

	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

---------------------------------------
-- ① 발동시 덱에서 서치
---------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0xc47) and c:IsAbleToHand() and c:IsMonster()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

---------------------------------------
-- ② 상대가 카드 효과 발동
---------------------------------------
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end

function s.xyzfilter1(c,e,tp)
	return c:IsFaceup() and c:IsSetCard(0xc47) and c:IsType(TYPE_XYZ)
		and Duel.IsExistingMatchingCard(s.xyzfilter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,c:GetRank()+1)
		or Duel.IsExistingMatchingCard(s.xyzfilter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,c:GetRank()+2)
end

function s.xyzfilter2(c,e,tp,mc,reqRank)
	return c:IsSetCard(0xc47) and c:IsType(TYPE_XYZ)
		and c:IsRank(reqRank)
		and mc:IsCanBeXyzMaterial(c)
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.xyzfilter1(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.xyzfilter1,tp,LOCATION_MZONE,0,1,nil,e,tp) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local tg=Duel.SelectTarget(tp,s.xyzfilter1,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsFaceup() or not tc:IsRelateToEffect(e) then return end

	local r1=tc:GetRank()+1
	local r2=tc:GetRank()+2

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local xc=Duel.SelectMatchingCard(tp,
		function(c) return s.xyzfilter2(c,e,tp,tc,r1) or s.xyzfilter2(c,e,tp,tc,r2) end,
		tp,LOCATION_EXTRA,0,1,1,nil):GetFirst()

	if not xc then return end

	Duel.BreakEffect()
	if Duel.SpecialSummon(xc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
		local mg=Group.FromCards(tc)
		xc:SetMaterial(mg)
		Duel.Overlay(xc,mg)
		xc:CompleteProcedure()
	end
end

---------------------------------------
-- ③ NS/SS → 상대 덱 위 3장 확인
---------------------------------------
function s.top3tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>=3 end
end

function s.top3op(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)<3 then return end
	Duel.ConfirmDecktop(1-tp,3)
	local g=Duel.GetDecktopGroup(1-tp,3)
	if #g==0 then return end
	Duel.SortDecktop(tp,1-tp,3)
end

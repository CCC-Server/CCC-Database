--ＢＦ－？？？ (임시 이름)
--Blackwing - ??? (temp)
local s,id=GetID()
function s.initial_effect(c)
	--① (발동 효과) : 필드에 몬스터가 없거나 / "BF" 몬스터가 존재하면,
	--패에서 이 카드를 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- ①: 1턴에 1번
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--② 일반 / 특수 소환 성공시 : "BF" 몬스터 또는
	--"블랙 페더 드래곤" 카드명이 쓰인 몬스터 서치
	--그 턴, 엑스트라 덱에서 어둠 속성 몬스터만 특소 가능
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1}) -- ②: 1턴에 1번
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)
end

--"BF" / "Black-Winged Dragon" 관련
s.listed_series={0x33}
s.listed_names={CARD_BLACK_WINGED_DRAGON}

--① 발동 조건 : 자신 필드에 몬스터가 0장 또는 "BF" 몬스터 존재
function s.bwfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x33)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- 몬스터가 1장도 없거나
	if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 then return true end
	-- 또는 "BF" 몬스터가 존재
	return Duel.IsExistingMatchingCard(s.bwfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end

--② 서치: "BF" 몬스터 또는 "Black-Winged Dragon" 카드명이 쓰인 몬스터
function s.thfilter(c)
	return c:IsType(TYPE_MONSTER)
		and (c:IsSetCard(0x33) or c:ListsCode(CARD_BLACK_WINGED_DRAGON))
		and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- 덱에서 서치
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
	-- 그 턴, 엑스트라 덱에서 어둠 속성 몬스터만 특수 소환 가능
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2)) -- “이 턴, 자신은 어둠 속성 몬스터밖에 엑스트라 덱에서 특수 소환할 수 없다.”
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

--엑스트라 덱에서 특수 소환 불가: 어둠 속성이 아닌 몬스터
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsAttribute(ATTRIBUTE_DARK)
end

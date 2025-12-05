--하이메타파이즈 티타노마키아
--Hi-Metaphys Titanomachia
local s,id=GetID()
function s.initial_effect(c)
	------------------------------------
	-- 특수 소환 몬스터 처리
	------------------------------------
	-- 이 카드는 통상 소환할 수 없다 / 정해진 방법으로만 특수 소환
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.FALSE)
	c:RegisterEffect(e0)
	-- 패 / 제외존에서의 특수 소환 절차
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND+LOCATION_REMOVED)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	------------------------------------
	-- ① 상대 효과 발동에 반응하는 퍼미션 효과
	-- (세 가지 선택지를 각각 1턴에 1번, 같은 턴에 같은 선택지 중복 불가)
	------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	-- ※ 여기에서의 1턴 1번 제한은 "각 선택지"를 밑에서 플래그로 관리
	-- e2:SetCountLimit(1,id) -- 텍스트상 필요 없으므로 삭제
	e2:SetCondition(s.qecon)
	e2:SetTarget(s.qetg)
	e2:SetOperation(s.qeop)
	c:RegisterEffect(e2)

	------------------------------------
	-- ② 제외되었을 때 : 다음 턴 스탠바이 페이즈에 처리
	-- 이 카드명의 ②의 효과는 1턴에 1번
	------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,4))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_REMOVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,id) -- ②만 카드명 1턴 1번
	e3:SetOperation(s.regop)
	c:RegisterEffect(e3)

	------------------------------------
	-- ③ 필드에서 효과로는 제외되지 않는다
	------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_CANNOT_REMOVE)
	e4:SetValue(s.rmlimit)
	c:RegisterEffect(e4)
end

s.listed_series={0x105} -- "메타파이즈" 카드군

------------------------------------
-- 특수 소환 절차
-- 이 카드는 통상 소환할 수 없다.
-- 제외 상태의 "메타파이즈" 카드 5종류를
-- 주인의 덱으로 되돌렸을 경우에만
-- 패 / 제외 상태에서 특수 소환할 수 있다.
------------------------------------
function s.tdfilter(c)
	-- 제외 상태의 "메타파이즈" 카드 (카드명 다르게 5종류 필요)
	return c:IsFaceup() and c:IsSetCard(0x105) and c:IsAbleToDeckAsCost()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	local g=Duel.GetMatchingGroup(s.tdfilter,tp,LOCATION_REMOVED,0,nil)
	return g:GetClassCount(Card.GetCode)>=5
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.GetMatchingGroup(s.tdfilter,tp,LOCATION_REMOVED,0,nil)
	-- 이름이 모두 다른 5장을 덱으로 되돌린다
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local sg=aux.SelectUnselectGroup(g,e,tp,5,5,aux.dncheck,1,tp,HINTMSG_TODECK)
	if #sg>0 then
		Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_COST)
	end
end

------------------------------------
-- ① 상대 효과 발동시의 퍼미션
-- ①: 상대 효과가 발동했을 때에 발동할 수 있다.
-- 이하의 효과 중 1개를 골라 적용한다.
-- 이 턴에 "하이메타파이즈 티타노마키아"의 효과로
-- 같은 효과를 적용할 수 없다.
-- ● 상대 필드의 카드 1장을 제외한다.
-- ● 상대 묘지의 카드 1장을 제외한다.
-- ● 제외 상태의 "메타파이즈" 몬스터 1장을 특수 소환한다.
------------------------------------
function s.qecon(e,tp,eg,ep,ev,re,r,rp)
	-- 상대가 카드/효과를 발동했을 때
	return ep~=tp
end
function s.metaspfilter(c,e,tp)
	-- 제외 상태의 "메타파이즈" 몬스터 (자신 제외존 기준)
	return c:IsFaceup() and c:IsSetCard(0x105)
		and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.qetg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- 각 선택지는 턴당 1번만(플래그로 관리, 같은 턴에 같은 선택지 불가)
	local b1=Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
		and Duel.GetFlagEffect(tp,id+1)==0
	local b2=Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_GRAVE,1,nil)
		and Duel.GetFlagEffect(tp,id+2)==0
	local b3=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.metaspfilter,tp,LOCATION_REMOVED,0,1,nil,e,tp)
		and Duel.GetFlagEffect(tp,id+3)==0
	if chk==0 then return b1 or b2 or b3 end

	local ops={}
	local opval={}
	local off=1
	if b1 then
		ops[off]=aux.Stringid(id,1) -- ● 상대 필드의 카드 1장 제외
		opval[off]=1
		off=off+1
	end
	if b2 then
		ops[off]=aux.Stringid(id,2) -- ● 상대 묘지의 카드 1장 제외
		opval[off]=2
		off=off+1
	end
	if b3 then
		ops[off]=aux.Stringid(id,3) -- ● 제외 상태의 "메타파이즈" 몬스터 1장 특수 소환
		opval[off]=3
		off=off+1
	end
	Duel.Hint(HINT_SELECTMSG,tp,0)
	local sel=Duel.SelectOption(tp,table.unpack(ops))+1
	local op=opval[sel]
	e:SetLabel(op)

	if op==1 then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD)
	elseif op==2 then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_GRAVE)
	else
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_REMOVED)
	end
end
function s.qeop(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==1 then
		-- 상대 필드의 카드 1장 제외
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
		if #g>0 then
			Duel.HintSelection(g)
			Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
		end
		Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE+PHASE_END,0,1)
	elseif op==2 then
		-- 상대 묘지의 카드 1장 제외
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_GRAVE,1,1,nil)
		if #g>0 then
			Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
		end
		Duel.RegisterFlagEffect(tp,id+2,RESET_PHASE+PHASE_END,0,1)
	elseif op==3 then
		-- 제외 상태의 "메타파이즈" 몬스터 1장 특수 소환
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.metaspfilter,tp,LOCATION_REMOVED,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
		Duel.RegisterFlagEffect(tp,id+3,RESET_PHASE+PHASE_END,0,1)
	end
end

------------------------------------
-- ② 제외되었을 때 : 다음 턴 스탠바이 페이즈 처리 등록
-- ②: 이 카드가 제외되었을 경우에 발동할 수 있다.
-- 다음 턴의 스탠바이 페이즈에 상대의 패 1장을 무작위로 골라
-- 그 카드와 이 카드를 주인의 덱으로 되돌린다.
------------------------------------
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 다음 턴의 스탠바이 페이즈에 1번만 발동
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetCountLimit(1)
	e1:SetCondition(s.stbcon)
	e1:SetOperation(s.stbop)
	e1:SetLabel(Duel.GetTurnCount())
	e1:SetReset(RESET_PHASE+PHASE_STANDBY+RESET_SELF_TURN,1)
	Duel.RegisterEffect(e1,tp)
end
function s.stbcon(e,tp,eg,ep,ev,re,r,rp)
	-- 이 카드가 제외된 턴의 다음 턴 스탠바이 페이즈
	return Duel.GetTurnCount()>e:GetLabel()
end
function s.stbop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 상대 패에서 무작위로 1장 덱으로 되돌린다
	local hg=Duel.GetFieldGroup(1-tp,LOCATION_HAND,0)
	if #hg>0 then
		local sg=hg:RandomSelect(tp,1)
		Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
	-- 이 카드 자신도 덱으로 되돌린다 (제외존에 있을 때만)
	if c:IsLocation(LOCATION_REMOVED) then
		Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end

------------------------------------
-- ③ 효과로는 제외되지 않는다
-- 필드의 이 카드는 효과로는 제외되지 않는다.
------------------------------------
function s.rmlimit(e,re,r,rp)
	return (r&REASON_EFFECT)~=0
end
